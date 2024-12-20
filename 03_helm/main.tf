data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
module "common_vars" {
  source = "../common-files"
}
module "outputs" {
  source = "../outputs_terraform_tfstate"
}

variable "password_grafana" {
  type = string
}
variable "ignore_delete_mapping_karpenter" {
  type = bool
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
  tags = {
    "enviroment" = module.common_vars.environment_name
  }
}

module "prometheus" {
  source = "./prometheus"
  cluster_name = local.cluster_name
  partition = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id
  cluster_oidc_issuer_url = local.cluster_oidc_issuer_url
  password_grafana = var.password_grafana
  vpc_id = module.outputs.vpc_id
  cluster_endpoint = local.cluster_endpoint
  cluster_version =local.cluster_version
  eks_oidc_provider_arn = local.eks_oidc_provider_arn

}

module "karpenter" {
  source = "./karpenter"
  cluster_name = local.cluster_name
  eks_oidc_provider_arn = local.eks_oidc_provider_arn
  environment_name = module.common_vars.environment_name
  cluster_endpoint = local.cluster_endpoint
  ignore_delete_mapping_karpenter = var.ignore_delete_mapping_karpenter
  cluster_certificate_authority_data = local.cluster_certificate_authority_data
}
