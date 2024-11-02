variable "environment_name" {
  description = "VPC for EKS and ArgoCD"
  type        = string
  default     = "production-01"
}

variable "eks_name" {
  description = "Name of cluster"
  type        = string
  default     = "EKS-ArgoCD-01"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC EKS-ArgoCD"
  type        = string
  default     = "10.0.0.0/16"
}

