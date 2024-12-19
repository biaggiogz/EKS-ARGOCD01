data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
module "common_vars" {
  source = "../common-files"
}
module "outputs" {
  source = "../outputs_terraform_tfstate"
}
variable "ignore" {
  type = bool
}
variable "password_grafana" {
  type = string
}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}
locals {
  cluster_endpoint = module.outputs.cluster_endpoint
  cluster_version = module.outputs.cluster_version
  eks_oidc_provider_arn = module.outputs.eks_oidc_provider_arn
  cluster_oidc_issuer_url = module.outputs.cluster_oidc_issuer_url
  cluster_name = module.common_vars.cluster_name
  cluster_certificate_authority_data = module.outputs.cluster_certificate_authority_data
  amp_namespace= "prometheus"
  amp_ingest_service_account= "prometheus-sa"
  region = "eu-north-1"
  KARPENTER_VERSION="1.0.8"
  tags = {
    "enviroment" = module.common_vars.environment_name
  }
}