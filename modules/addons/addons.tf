/*resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = local.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  preserve         = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  addon_version = "v1.37.0-eksbuild.1"
  service_account_role_arn = module.role_ebs_csi_driver.iam_role_arn

  lifecycle {
    ignore_changes = [addon_version, resolve_conflicts_on_create, resolve_conflicts_on_update]
  }

}
*/

/*
resource "aws_iam_role" "ebs_csi_driver" {
  name = "ebs_csi_driver"

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
            "${replace(local.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
  lifecycle {
    ignore_changes = [name]
  }
}
*/



