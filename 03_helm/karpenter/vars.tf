variable "cluster_name" {
  type = string
}

variable "eks_oidc_provider_arn" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "cluster_endpoint" {
  type =string
}

variable "ignore_delete_mapping_karpenter" {
  type = bool
}

variable "cluster_certificate_authority_data" {
  type = string
}

