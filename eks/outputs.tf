output "cluster_name" {
  description = "Cluster Hub name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "Cluster Hub endpoint"
  value       = module.eks.cluster_endpoint
  sensitive = true
}
output "cluster_version" {
  value = module.eks.cluster_version
}
output "cluster_certificate_authority_data" {
  description = "Cluster Hub certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "hub_node_security_group_id" {
  description = "Cluster Hub region"
  value       = module.eks.node_security_group_id
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
  sensitive = true

}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
  sensitive = true

}
output "oidc_provider" {
  value = module.eks.oidc_provider
  sensitive =  true
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks_cluster_status" {
  description = "Amazon EKS Cluster Status"
  value       = module.eks.cluster_status
}

