module "sso" {
  source = "../../modules/sso"
  role   = var.sso_role
}

module "backend" {
  source         = "../../modules/backend"
  bucket         = var.bucket
  region         = var.region
  dynamodb_table = var.dynamodb_table
  encrypt        = var.encrypt
}