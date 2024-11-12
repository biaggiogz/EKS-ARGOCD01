output "kubernetes_version" {
  description = "EKS version"
  value       = var.kubernetes_version
}
output "environment_name" {
  description = "VPC for EKS and ArgoCD"
  value       = var.environment_name
}

output "eks_admin_role_name" {
  description = "EKS-ArgoCD admin role"
  value       = var.eks_admin_role_name
}

output "addons" {
  description = "EKS addons"
  value = var.addons
}

output "authentication_mode" {
  value       = var.authentication_mode
}

output "region" {
  value = var.region
}


output "cluster_name" {
  description = "Name of cluster"
  value       = var.cluster_name
}

output "aws_partition" {
  value       = var.aws_partition
}

output "aws_account_id" {
  value       = var.aws_account_id
}


output "r53_hosted_zone_id" {
  value       = var.r53_hosted_zone_id
}

output "public_dns_name" {
  value       = var.public_dns_name
}

output "enable_airflow" {
  value       =  var.enable_airflow
}

output "create_iam_roles" {

  value       = var.create_iam_roles
}

output "ebs_csi_policy_name" {
  value   = var.ebs_csi_policy_name
}

output "db_private_subnets" {
  description = "Private Subnets CIDRs. 254 IPs per Subnet/AZ for Airflow DB."
  value       = var.db_private_subnets
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       =  var.vpc_cidr
}

output "public_subnets" {
  description = "Public Subnets CIDRs. 62 IPs per Subnet/AZ"
  value       = var.public_subnets
}

output "eks_data_plane_subnet_secondary_cidr" {
  description = "Secondary CIDR blocks. 32766 IPs per Subnet per Subnet/AZ for EKS Node and Pods"
  value       = var.eks_data_plane_subnet_secondary_cidr
}

output "secondary_cidr_blocks" {
  value       = var.secondary_cidr_blocks
}
output "private_subnets" {
  value       = var.private_subnets
}

output "enable_vpc_endpoints" {
  value = var.enable_vpc_endpoints
}