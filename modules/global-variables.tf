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


variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "EKS-01"
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

variable "ebs_csi_policy_name" {
  default = "Amazon_EBS_CSI_Driver"
}

variable "db_private_subnets" {
  description = "Private Subnets CIDRs. 254 IPs per Subnet/AZ for Airflow DB."
  default     = ["10.0.20.0/26", "10.0.21.0/26"]
  type        = list(string)
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

variable "eks_data_plane_subnet_secondary_cidr" {
  description = "Secondary CIDR blocks. 32766 IPs per Subnet per Subnet/AZ for EKS Node and Pods"
  default     = ["100.64.0.0/17", "100.64.128.0/17"]
  type        = list(string)
}

variable "secondary_cidr_blocks" {
  description = "Secondary CIDR blocks to be attached to VPC"
  default     = ["100.64.0.0/16"]
  type        = list(string)
}
variable "private_subnets" {
  description = "Private Subnets CIDRs. 254 IPs per Subnet/AZ for Private NAT + NLB + Airflow + EC2 Jumphost etc."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  type        = list(string)
}
variable "namespaces" {
  type    = list(string)
  default = ["integration", "development"]
}

variable "roles" {
  type = map(object({
    namespace = string
    name      = string
  }))
  default = {
    dev = {
      namespace = "development"
      name      = "dev-role"
    }
    integ = {
      namespace = "integration"
      name      = "integ-role"
    }
  }
}

variable "enable_vpc_endpoints" {
  type = bool
  default = true
}