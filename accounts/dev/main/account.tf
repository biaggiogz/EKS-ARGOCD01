module "common_vars" {
  source = "../../../config"
}

module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "5.46.0"

  account_alias = "${module.common_vars.project}-${var.environment}"

  create_account_password_policy = true
  max_password_age               = 60
  minimum_password_length        = 30
  require_numbers                = true
  require_lowercase_characters   = true
  require_symbols                = true
  require_uppercase_characters   = true
  password_reuse_prevention      = 5
  allow_users_to_change_password = false
}

data "aws_caller_identity" "current" {}