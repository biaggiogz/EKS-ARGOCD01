


provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

provider "kubectl" {
  apply_retry_count      = 30
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.eks.token
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name                   = data.terraform_remote_state.global-variables.outputs.cluster_name
  cluster_version                = data.terraform_remote_state.global-variables.outputs.kubernetes_version
  cluster_endpoint_public_access = true
  create_iam_role = false
  iam_role_arn = aws_iam_role.eks_admin.arn
  authentication_mode = data.terraform_remote_state.global-variables.outputs.authentication_mode
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = compact([for subnet_id, cidr_block in zipmap(local.private_subnets,local.private_subnets_cidr_blocks) : substr(cidr_block, 0, 4) == "100." ? subnet_id : null])
  enable_cluster_creator_admin_permissions = true



  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]
  ))


  access_entries = {

    eks_admin = {
      kubernetes_groups = []

      principal_arn = aws_iam_role.eks_admin.arn
      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    core_node_group = {
      name       = "core-node-group-${local.cluster_name}"
      description = "EKS Core node group for hosting critical add-ons"
      subnet_ids = compact([for subnet_id, cidr_block in zipmap(local.private_subnets, local.private_subnets_cidr_blocks) : substr(cidr_block, 0, 4) == "100." ? subnet_id : null])

      min_size      = 2
      max_size      = 4
      desired_size  = 3
      ami_type      = "AL2_x86_64"
      capacity_type = "SPOT"

      instance_types = ["t3.medium"]
      #instance_types = ["m5.xlarge", "m5.2xlarge"]

      ebs_optimized = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 150
            volume_type = "gp3"
          }
        }
      }
      labels = {
        WorkerType    = "ON_SPOT"
        NodeGroupType = "core"
        lifecycle = "Ec2Spot"

      }

      tags = merge(local.tags, {
        Name                     = "core-node-grp",
        "karpenter.sh/discovery" = local.name
      })
    }
  }


  tags = {
    Blueprint  = data.terraform_remote_state.global-variables.outputs.cluster_name
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_loadbalancer_policy

  ]
}



resource "kubernetes_config_map" "aws-auth" {
  data = {
    "mapRoles" = <<EOT
- rolearn: arn:aws:iam::891377107274:role/KarpenterNodeRole-EKS-01
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOT
  }

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}