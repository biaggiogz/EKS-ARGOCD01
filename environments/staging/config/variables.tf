variable "environment" {
  type        = string
  description = "Environment name"
}

variable "sso_role" {
  type        = string
  description = "SSO role"
}

variable "profile" {
  type        = string
  description = "AWS profile"
}

variable "bucket" {
  type        = string
  description = "S3 bucket for Terraform backend"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "encrypt" {
  type        = bool
  description = "Enable DynamoDB server-side encryption"
}

variable "dynamodb_table" {
  type        = string
  description = "DynamoDB table name for Terraform backend"
}