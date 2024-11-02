variable "environment_name" {
  description = "VPC for EKS and ArgoCD"
  type        = string
  default     = "production-01"
}

variable "eks_name" {
  description = "Name of cluster"
  type        = string
  default     = "EKS-01"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC EKS-ArgoCD"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_cidr_blocks" {
  description = "Secondary CIDR blocks to be attached to VPC"
  default     = ["100.64.0.0/16"]
  type        = list(string)
}

variable "db_private_subnets" {
  description = "Private Subnets CIDRs. 254 IPs per Subnet/AZ for Airflow DB."
  default     = ["10.0.20.0/26", "10.0.21.0/26"]
  type        = list(string)
}
