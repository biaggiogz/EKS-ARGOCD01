

locals {
  name            = data.terraform_remote_state.global-variables.outputs.environment_name
  enable_vpc_endpoints     = data.terraform_remote_state.global-variables.outputs.enable_vpc_endpoints
  region          = data.aws_region.current.id
  eks_name        = data.terraform_remote_state.global-variables.outputs.cluster_name
  vpc_cidr        = data.terraform_remote_state.global-variables.outputs.vpc_cidr
  num_of_subnets  = min(length(data.aws_availability_zones.available.names), 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)

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
  version = "5.15.0"

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
/*
locals {
  unique_private_subnets = distinct(module.vpc.private_subnets)
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.15.0"

  create             = local.enable_vpc_endpoints
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  endpoints = merge({
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${local.name}-s3"
      }
    }
  },
    { for service in toset(["autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages", "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"]) :
      replace(service, ".", "_") =>
      {
        service             = service
        subnet_ids          = slice(local.unique_private_subnets, 0, length(local.azs))  # Ensures one subnet per AZ
        private_dns_enabled = true
        tags                = { Name = "${local.name}-${service}" }
      }
    })

  tags = local.tags
  depends_on = [module.vpc]
}

module "vpc_endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  create = local.enable_vpc_endpoints

  name        = "${local.name}-vpc-endpoints"
  description = "Security group for VPC endpoint access"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      description = "VPC CIDR HTTPS"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
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
*/