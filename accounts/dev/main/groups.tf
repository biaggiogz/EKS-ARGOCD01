
module "iam_group_auditors" {
  source  = "terraform-aws-modules/iam/aws//examples/iam-group-with-policies"
  version = "5.46.0"
  name = "auditors"

  group_users = [
    module.user_auditor_ci.iam_user_name,
  ]

  custom_group_policy_arns = [
  ]
}