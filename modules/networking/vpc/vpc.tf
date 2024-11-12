data "aws_availability_zones" "available" {}
data "aws_region" "current" {}



locals {
  name            = data.terraform_remote_state.global-variables.outputs.environment_name
  region          = data.aws_region.current.id
  eks_name        = data.terraform_remote_state.global-variables.outputs.cluster_name
  vpc_cidr        = data.terraform_remote_state.global-variables.outputs.vpc_cidr
  num_of_subnets  = min(length(data.aws_availability_zones.available.names), 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)
  private_subnets = data.terraform_remote_state.global-variables.outputs.private_subnets
  eks_data_plane_subnet_secondary_cidr = data.terraform_remote_state.global-variables.outputs.eks_data_plane_subnet_secondary_cidr
  tags = {
    Blueprint  = local.name
    #GithubRepo = "https://github.com/biaggiogz/EKS/tree/EKS-ArgoCD"
  }

}

module "vpc" {
  name = local.name

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0.0"

  cidr = local.vpc_cidr
  azs  = local.azs

  secondary_cidr_blocks = data.terraform_remote_state.global-variables.outputs.secondary_cidr_blocks

  private_subnets = concat(local.private_subnets, local.eks_data_plane_subnet_secondary_cidr)

  public_subnets = data.terraform_remote_state.global-variables.outputs.public_subnets

  database_subnets                   = data.terraform_remote_state.global-variables.outputs.db_private_subnets
  create_database_subnet_group       = true
  create_database_subnet_route_table = true


  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  enable_dns_support   = true

  /*manage_default_network_acl    = false
  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )*/

  public_subnet_tags = {
    "kubernetes.io/role/elb"                            = 1
    "kubernetes.io/cluster/${local.eks_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                   = 1
    "kubernetes.io/cluster/${local.eks_name}" = "shared"
    "karpenter.sh/discovery" = local.name


  }

  tags = local.tags
}