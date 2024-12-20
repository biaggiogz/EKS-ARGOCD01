data "aws_availability_zones" "available" {}
module "common_vars" {
  source = "../common-files"


}

locals {
  num_of_subnets  = min(length(data.aws_availability_zones.available.names), 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  cluster_name = module.common_vars.cluster_name
  tags = {
    "enviroment" = module.common_vars.environment_name
  }

}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.10.0"

  name = local.cluster_name
  cidr = module.common_vars.vpc_cidr
  azs  = local.azs

  secondary_cidr_blocks = module.common_vars.secondary_cidr_blocks

  private_subnets = concat(module.common_vars.private_subnets, module.common_vars.eks_data_plane_subnet_secondary_cidr)

  public_subnets = module.common_vars.public_subnets

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

/*
module "vpc_endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create = true

  name        = "${local.cluster_name}-vpc-endpoints"
  description = "Security group for VPC endpoint access"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      description = "VPC CIDR HTTPS"
      cidr_blocks = join(",", [module.vpc.vpc_cidr_block], module.vpc.vpc_secondary_cidr_blocks)
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      description = "All egress HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.14.0"

  create = true

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  endpoints = merge({
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat(module.vpc.public_route_table_ids, module.vpc.private_route_table_ids)
      tags = {
        Name = "${local.cluster_name}-s3"
      }
    }
  },
    { for service in toset(["autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages", "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"]) :
      replace(service, ".", "_") =>
      {
        service             = service
        subnet_ids          = module.vpc.private_subnets
        private_dns_enabled = true
        tags                = { Name = "${local.cluster_name}-${service}" }
      }
    })

  tags = local.tags
}*/