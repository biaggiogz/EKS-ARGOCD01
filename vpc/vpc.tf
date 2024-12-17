data "aws_availability_zones" "available" {}
module "common_vars" {
  source = "../common-files"


}

locals {
  num_of_subnets  = min(length(data.aws_availability_zones.available.names), 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_name = module.common_vars.cluster_name
  vpc_cidr = module.common_vars.vpc_cidr
  tags = {
    "enviroment" = module.common_vars.environment_name
  }

}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.10.0"

  name = local.cluster_name
  cidr = local.vpc_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 3, k + length(local.azs))]
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 3, k)]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  enable_dns_support   = true
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.cluster_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.cluster_name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.cluster_name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    "karpenter.sh/discovery" = local.cluster_name
  }

  tags = local.tags
}
