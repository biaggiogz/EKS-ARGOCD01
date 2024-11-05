locals {
  roles = {
    k8sAdmin = "Kubernetes administrator role (for AWS IAM Authenticator for Kubernetes)."
    k8sDev   = "Kubernetes developer role (for AWS IAM Authenticator for Kubernetes)."
    k8sInteg = "Kubernetes role for integration namespace in quick cluster."
  }
  users = {
    Biaggio   = "k8sAdmin"
    Mate01    = "k8sDev"
    Mate02    = "k8sInteg"
  }
}

data "aws_caller_identity" "current" {}


resource "aws_iam_role" "kubernetes_roles" {
  for_each = local.roles

  name               = each.key
  description        = each.value
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    CreatedBy = "Terraform"
    Purpose   = "Kubernetes Access"
  }
}

resource "aws_iam_group" "kubernetes_groups" {
  for_each = local.roles
  name     = each.key
}

resource "aws_iam_group_policy" "kubernetes_group_policies" {
  for_each = local.roles
  name     = "${each.key}-policy"
  group    = aws_iam_group.kubernetes_groups[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeOrganizationAccountRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.kubernetes_roles[each.key].arn
      }
    ]
  })
}
resource "aws_iam_user" "kubernetes_users" {
  for_each = local.users
  name     = each.key
  tags = {
    CreatedBy = "Terraform"
    Role      = each.value
  }
}

resource "aws_iam_user_group_membership" "user_group_memberships" {
  for_each = local.users
  user     = aws_iam_user.kubernetes_users[each.key].name
  groups   = [aws_iam_group.kubernetes_groups[each.value].name]
}

output "role_arns" {
  value = {for k, v in aws_iam_role.kubernetes_roles : k => v.arn}
}

output "group_arns" {
  value = {for k, v in aws_iam_group.kubernetes_groups : k => v.arn}
}

output "user_arns" {
  value = {for k, v in aws_iam_user.kubernetes_users : k => v.arn}
}