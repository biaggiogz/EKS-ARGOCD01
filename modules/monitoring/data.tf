data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_partition" "current" {}


data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-dev-01"
    key            = "modules/vpc/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-dev-01"
    key            = "modules/eks/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

locals  {
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  eks_oidc_provider_arn = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
  oidc_provider = data.terraform_remote_state.eks.outputs.oidc_provider
  cluster_endpoint = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  cluster_version = data.terraform_remote_state.eks.outputs.cluster_version
  token                  = data.terraform_remote_state.eks.outputs.kubectl.token
  cluster_oidc_issuer_url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  region = "eu-north-1"
  amp_namespace              = "kube-prometheus-stack"
  amp_ingest_service_account = "amp-iamproxy-ingest-service-account"

}
locals {

  tags = {
    branch  = "dev-01"
  }

}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

variable "secret_grafana" {
  type = string
  sensitive = true
}