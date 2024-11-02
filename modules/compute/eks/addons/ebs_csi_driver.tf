

/*resource "aws_iam_policy" "ebs_csi_policy" {
  name        = var.ebs_csi_policy_name
  path        = "/"
  description = "IAM policy for EBS CSI Driver"
  policy      = file("/home/aniking/Documents/IdeaProjects/ArchitectElevatorAWS/modules/compute/eks/addons/policies/ebs_csi_policy.json")
}*/

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name = "eksctl-${var.cluster_name}-addon-aws-ebs-csi-driver-role"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               =  data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.namespace_csi_driver}:efs-csi-controller-sa"]
    }
  }
}
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = "v1.36.0-eksbuild.1"  # Use the latest version
  service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [module.ebs_csi_irsa_role]
}

/*resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = var.namespace_csi_driver
    annotations = {
      "eks.amazonaws.com/role-arn" = module.ebs_csi_irsa_role.iam_role_arn
    }
  }
  depends_on = [module.ebs_csi_irsa_role]
}*/
/*
resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.36.0"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account.ebs_csi_controller_sa.metadata[0].name
  }

  depends_on = [kubernetes_service_account.ebs_csi_controller_sa]
}
*/