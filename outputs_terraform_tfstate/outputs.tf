data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "tf-state-eks-03"
    key            = "vpc/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true

  }
}
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket         = "tf-state-eks-03"
    key            = "eks/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true

  }
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = data.terraform_remote_state.vpc.outputs.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = data.terraform_remote_state.vpc.outputs.public_subnets
}


output "vpc_cidr_block" {
  value = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}

output "cluster_name" {
  description = "Cluster Hub name"
  value       = data.terraform_remote_state.eks.outputs.cluster_name
}
output "cluster_endpoint" {
  description = "Cluster Hub endpoint"
  value       = data.terraform_remote_state.eks.outputs.cluster_endpoint
  sensitive = true
}
output "cluster_version" {
  value = data.terraform_remote_state.eks.outputs.cluster_version
}
output "cluster_certificate_authority_data" {
  description = "Cluster Hub certificate_authority_data"
  value       = data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data
  sensitive = true
}

output "hub_node_security_group_id" {
  description = "Cluster Hub region"
  value       = data.terraform_remote_state.eks.outputs.hub_node_security_group_id
}

output "cluster_oidc_issuer_url" {
  value = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  sensitive = true

}

output "eks_oidc_provider_arn" {
  value = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
  sensitive = true

}
output "oidc_provider" {
  value = data.terraform_remote_state.eks.outputs.oidc_provider
}

output "eks_cluster_status" {
  description = "Amazon EKS Cluster Status"
  value       = data.terraform_remote_state.eks.outputs.eks_cluster_status
}

