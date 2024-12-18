data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

module "common_vars" {
  source = "../common-files"
}
module "eks_outputs" {
  source = "../outputs_terraform_tfstate"
}

locals {
  cluster_name = module.common_vars.cluster_name
  cluster_endpoint = module.eks_outputs.cluster_endpoint
  cluster_version = module.eks_outputs.cluster_version
  eks_oidc_provider_arn = module.eks_outputs.eks_oidc_provider_arn
  cluster_oidc_issuer_url = module.eks_outputs.cluster_oidc_issuer_url
  eks_status = module.eks_outputs.eks_cluster_status
  cluster_certificate_authority_data = module.eks_outputs.cluster_certificate_authority_data
  region = "eu-north-1"
  tags = {
    "enviroment" = module.common_vars.environment_name
  }

}

/*
module "eks_blueprints_kubernetes_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.18.0"
  cluster_name      = var.cluster_name
  cluster_endpoint  = local.eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true
  enable_cert_manager                 = true
  enable_aws_efs_csi_driver = true
  enable_aws_fsx_csi_driver = true
  cert_manager = {
    chart_version = "v1.16.0"
  }

  aws_efs_csi_driver = {
    namespace     = "kube-system"
    chart_version = "3.0.6"
  }

  aws_load_balancer_controller = {
    chart_version = "v1.10.8"
  }

  aws_fsx_csi_driver = {
    namespace     = "kube-system"
    chart_version = "1.9.0"
  }

  tags = local.tags
}
*/

resource "aws_eks_addon" "ebs_csi_driver" {
  count = local.eks_status == "ACTIVE" ? 1 : 0
  cluster_name = local.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  preserve         = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  addon_version = "v1.37.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  lifecycle {
    ignore_changes = [addon_version, resolve_conflicts_on_create, resolve_conflicts_on_update]
  }
   depends_on = [aws_iam_role.ebs_csi_driver, kubernetes_service_account.ebs_csi_controller_sa]
}

resource "aws_iam_role" "ebs_csi_driver" {
  name = "ebs-csi-driver-${local.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.cluster_oidc_issuer_url, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(local.cluster_oidc_issuer_url, "https://", "")}:sub": "kube-system:ebs-csi-controller-sa"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "pods.eks.amazonaws.com"
        },
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }

    ]
  })
}

resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver.arn
    }
  }
}
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}
resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name           = local.cluster_name
  namespace              = "kube-system"
  service_account        = kubernetes_service_account.ebs_csi_controller_sa.metadata[0].name
  role_arn               = aws_iam_role.ebs_csi_driver.arn
}
