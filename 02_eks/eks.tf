#
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

module "common_vars" {
  source = "../common-files"
}

locals {
  region = "eu-north-1"
  tags = {
    "enviroment" = module.common_vars.environment_name
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name                   = module.common_vars.cluster_name
  cluster_version                = module.common_vars.kubernetes_version
  cluster_endpoint_public_access = true
  create_iam_role = false
  iam_role_arn = aws_iam_role.eks_admin.arn
  authentication_mode = module.common_vars.authentication_mode
  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = []
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = compact([for subnet_id, cidr_block in zipmap(data.terraform_remote_state.vpc.outputs.private_subnets,data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks) : substr(cidr_block, 0, 4) == "100." ? subnet_id : null])

  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]
  ))

  access_entries = {

    eks_admin = {
      kubernetes_groups = []

      principal_arn     = aws_iam_role.eks_admin.arn
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

  eks_managed_node_groups = {
    initial = {

      name= "node-group"
      create_security_group = false
      create_launch_template = true
      launch_template_os     = "amazonlinux2eks"
      instance_types = ["t3.medium"]
      min_size     = 0
      max_size     = 4
      desired_size = 2
      ami_type = "AL2_x86_64"
      capacity_type = "SPOT"
      create_iam_role = false
      iam_role_arn = aws_iam_role.eks_nodes.arn
      ebs_optimized = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 50
            volume_type = "gp3"
          }
        }
      }
      labels = {
        "karpenter.sh/discovery" = module.common_vars.cluster_name
        "karpenter.sh/controller" = "true"
      }
    }
  }

  cluster_addons = {
    eks-pod-identity-agent ={
      most_recent = true
    }

    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

    coredns                = {
      most_recent = true
    }
    kube-proxy             = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          WARM_IP_TARGET           = "5"
          MINIMUM_IP_TARGET        = "10"
          ENABLE_POD_ENI           = "true"
          # ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          # AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = true
        }
      })
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
    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
  node_security_group_tags = merge(local.tags, {
    "karpenter.sh/discovery" = module.common_vars.cluster_name
  })
  tags = local.tags
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_loadbalancer_policy
  ]

}

