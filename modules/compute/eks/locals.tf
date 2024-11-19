locals {
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  private_subnets_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  region = data.terraform_remote_state.global-variables.outputs.region
  name = data.terraform_remote_state.global-variables.outputs.environment_name
  cluster_name = data.terraform_remote_state.global-variables.outputs.cluster_name
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  labels = {
    environment                    = data.terraform_remote_state.global-variables.outputs.environment_name
    "app.kubernetes.io/managed-by"  = "Terraform"
    "app.kubernetes.io/part-of"   = data.terraform_remote_state.global-variables.outputs.environment_name
  }
  tags = {
    Blueprint  = local.name
  }
}