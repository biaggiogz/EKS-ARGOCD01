output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = <<-EOT
    aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ekshub
  EOT
}

output "cluster_name" {
  description = "Cluster Hub name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "Cluster Hub endpoint"
  value       = module.eks.cluster_endpoint
}
output "cluster_certificate_authority_data" {
  description = "Cluster Hub certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}
output "cluster_region" {
  description = "Cluster Hub region"
  value       = local.region
}
output "hub_node_security_group_id" {
  description = "Cluster Hub region"
  value       = module.eks.node_security_group_id
}


output "helm_kubernetes" {
  value = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
  sensitive = true

}

output "kubernetes" {
  value = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
  sensitive = true

}

output "kubectl" {
  value = {
    apply_retry_count      = 30
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    load_config_file       = false
    token                  = data.aws_eks_cluster_auth.eks.token
  }
  sensitive = true

}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
  sensitive = true

}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
  sensitive = true

}
/*
output "eks_managed_node_group_subnets" {
  description = "List of subnet IDs used for EKS managed node groups"
  value       = values(module.eks.eks_managed_node_groups)[*].subnet_ids
}
*/
