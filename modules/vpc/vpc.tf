module "vpc" {
  name = var.cluster_name

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.15.0"

  cidr = var.vpc_cidr
  azs  = local.azs

  secondary_cidr_blocks = var.eks_data_plane_subnet_secondary_cidr

  private_subnets = concat(var.private_subnets, var.eks_data_plane_subnet_secondary_cidr)

  public_subnets = var.public_subnets

  create_database_subnet_group       = false
  create_database_subnet_route_table = false


  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true
  enable_dns_support   = true


  public_subnet_tags = {
    "kubernetes.io/role/elb"                            = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                   = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery" = var.cluster_name

  }

  tags = local.tags
}