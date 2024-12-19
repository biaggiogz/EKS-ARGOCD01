variable "cluster_name" {
  type = string
}

variable "partition" {
  type = string
}

variable "account_id" {
  type = string
}

variable "cluster_oidc_issuer_url" {
  type = string
}

variable "password_grafana" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "eks_oidc_provider_arn" {
  type =string
}