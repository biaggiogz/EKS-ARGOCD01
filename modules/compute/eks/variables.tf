variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.30"
}
variable "environment_name" {
  description = "VPC for EKS and ArgoCD"
  type        = string
  default     = "production-01"
}

variable "eks_admin_role_name" {
  description = "EKS-ArgoCD admin role"
  type        = string
  default     = "EKS-Admin"
}

variable "addons" {
  description = "EKS addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = false
    enable_aws_argocd = false
  }
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "eu-north-1"
}

variable "k8s_version" {
  description = "Version of cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "EKS-01"
}

variable "env" {
  description = "env of cluster"
  type        = string
  default     = "production-01"
}

variable "aws_partition" {
  description = "aws partition"
  type        = string
  default     = "aws"
}

variable "aws_account_id" {
  description = "aws account id"
  type        = string
  default     = "$(aws sts get-caller-identity --query Account --output text)"
}

variable "ssh_key_name" {
  description = "ssh key"
  type        = string
  default     = "CloudAWS.pem"
}
variable "r53_hosted_zone_id" {
  description = "AWS Route 53 Hosted Zone ID"
  type        = string
  default = "Z10018721PYSS6EZR6SR5"
}

variable "public_dns_name" {
  description = "Public DNS name created in AWS Route 53"
  type        = string
  default = "infinitydataservices.com"
}


variable "enable_airflow" {
  description = "Enable Apache Airflow"
  type        = bool
  default     = true
}

variable "create_iam_roles" {
  description = "Whether to create IAM roles or use existing ones"
  type        = bool
  default     = true
}