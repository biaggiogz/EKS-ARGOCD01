module "user_auditor_ci" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.46.0"
  name                    = "auditor.ci"
  force_destroy           = true
  password_reset_required = true

  create_iam_user_login_profile = false
  create_iam_access_key         = true
  upload_iam_user_ssh_key       = false

  pgp_key = file("keys/machine.auditor.ci")
}