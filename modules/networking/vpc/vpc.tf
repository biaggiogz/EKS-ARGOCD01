data "aws_availability_zones" "available" {}
data "aws_region" "current" {}



locals {
  name            = var.environment_name
  region          = data.aws_region.current.id
  eks_name        = var.eks_name
  vpc_cidr        = var.vpc_cidr
  num_of_subnets  = min(length(data.aws_availability_zones.available.names), 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  tags = {
    Blueprint  = local.name
    #GithubRepo = "https://github.com/biaggiogz/EKS/tree/EKS-ArgoCD"
  }
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k + 10)]
  #secondary_cidr_blocks = var.secondary_cidr_blocks


  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  enable_dns_support   = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }


  # ------------------------------
  # Private Subnets for Airflow metadata store
  database_subnets                   = var.db_private_subnets
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                            = 1
    "kubernetes.io/cluster/${local.eks_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                   = 1
    "kubernetes.io/cluster/${local.eks_name}" = "shared"

  }

  tags = local.tags
}