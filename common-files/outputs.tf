output "vpc_cidr" {
  value = var.vpc_cidr
}

output "environment_name" {
  value = var.environment_name
}

output "cluster_name" {
  value = var.cluster_name
}
output "public_subnets" {
  value = var.public_subnets
}


output "kubernetes_version" {
  value = var.kubernetes_version
}

output "authentication_mode" {
  value = var.authentication_mode
}

output "private_subnets" {
  value = var.private_subnets
}

output "secondary_cidr_blocks" {
  value =  var.secondary_cidr_blocks
}
output "eks_data_plane_subnet_secondary_cidr" {
  value = var.eks_data_plane_subnet_secondary_cidr
}

