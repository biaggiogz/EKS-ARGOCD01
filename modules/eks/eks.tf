

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name                   = var.cluster_name
  cluster_version                = var.kubernetes_version
  cluster_endpoint_public_access = true
  create_iam_role = false
  iam_role_arn = aws_iam_role.eks_admin.arn
  authentication_mode = var.authentication_mode

  # Combine root account, current user/role and additional roles to be able to access the cluster KMS key - required for terraform updates
  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]
  ))

  enable_cluster_creator_admin_permissions = true
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

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets
  #      subnet_ids = compact([for subnet_id, cidr_block in zipmap(local.private_subnets, local.private_subnets_cidr_blocks) : substr(cidr_block, 0, 4) == "100." ? subnet_id : null])

  eks_managed_node_groups = {
    initial = {
      name= "node-group"

      instance_types = ["t3.medium"]

      min_size     = 0
      max_size     = 4
      desired_size = 3
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
        WorkerType    = "ON_SPOT"
        NodeGroupType = "core"
        lifecycle = "Ec2Spot"
        intent = "control-apps"


      }
    }
  }

  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent = true
    }
    coredns                = {
      most_recent = true
    }
    kube-proxy             = {
      most_recent = true
    }
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          # ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          # AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = true
        }
      })
    }
  }
  tags = local.tags
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_loadbalancer_policy
  ]
}
