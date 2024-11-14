locals {
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  private_subnets_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  region = data.terraform_remote_state.global-variables.outputs.region
  name = data.terraform_remote_state.global-variables.outputs.environment_name
  cluster_name = data.terraform_remote_state.global-variables.outputs.cluster_name
  tags = {
    Blueprint  = local.name
  }
}