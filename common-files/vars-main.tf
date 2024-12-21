
variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.30"
}
variable "environment_name" {

  type        = string
  default     = "dev-03"
}

variable "eks_admin_role_name" {
  description = "EKS-ArgoCD admin role"
  type        = string
  default     = "EKS-Admin"
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


variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "eks-03"
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

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
  type        = string
}



variable "public_subnets" {
  description = "Public Subnets CIDRs. 62 IPs per Subnet/AZ"
  default     = ["10.0.0.0/26", "10.0.0.64/26"]
  type        = list(string)
}

variable "private_subnets" {
  description = "Private Subnets CIDRs. 254 IPs per Subnet/AZ for Private NAT + NLB + Airflow + EC2 Jumphost etc."
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  type        = list(string)
}

variable "secondary_cidr_blocks" {
  description = "Secondary CIDR blocks to be attached to VPC"
  default     = ["100.64.0.0/16"]
  type        = list(string)
}
variable "eks_data_plane_subnet_secondary_cidr" {
  description = "Secondary CIDR blocks. 32766 IPs per Subnet per Subnet/AZ for EKS Node and Pods"
  default     = ["100.64.0.0/17", "100.64.128.0/17"]
  type        = list(string)
}