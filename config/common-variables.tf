#================================#
# Common variables               #
#================================#
# config/backend.config
variable "region" {
  type        = string
  description = "AWS Region"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "Must be a valid AWS region name."
  }
}

variable "primary_region" {
  type        = string
  description = "AWS Region"
}

variable "profile" {
  type        = string
  description = "AWS Profile (required by the backend but also used for other resources)"
}


variable "bucket" {
  type        = string
  description = "AWS S3 TF State Backend Bucket"
}

variable "dynamodb_table" {
  type        = string
  description = "AWS DynamoDB TF Lock state table name"
}

variable "encrypt" {
  type        = bool
  description = "Enable AWS DynamoDB with server side encryption"
}

# config/base.config
#=============================#
# Project Variables           #
#=============================#
variable "project" {
  type        = string
  description = "Project Name"
}

variable "project_long" {
  type        = string
  description = "Project Long Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

# config/extra.config
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "region_secondary" {
  type        = string
  description = "AWS Secondary Region for HA"
}

variable "accounts" {
  type = map(object({
    email = string
    id    = number
  }))
  description = "AWS accounts information"
}
variable "external_accounts" {
  type = map(object({
    aws_account_id  = string
    aws_external_id = string
  }))
  description = "External accounts integration"
}

#=============================#
# AWS SSO  Variables          #
#=============================#
variable "sso_role" {
  description = "SSO Role Name"
}

variable "sso_enabled" {
  type        = string
  description = "Enable SSO Service"
}

variable "sso_region" {
  type        = string
  description = "SSO Region"
}

variable "sso_start_url" {
  type        = string
  description = "SSO Start Url"
}

#===========================================#
# Networking                                #
#===========================================#
variable "enable_tgw" {
  description = "Enable Transit Gateway Support"
  type        = bool
  default     = false
}

variable "enable_tgw_multi_region" {
  description = "Enable Transit Gateway multi region support"
  type        = bool
  default     = false
}

variable "tgw_cidrs" {
  description = "CIDRs to be added as routes to public RT"
  type        = list(string)
  default     = []
}

#===========================================#
# Security compliance
#===========================================#
variable "enable_inspector" {
  description = "Turn inspector on/off"
  type        = bool
  default     = false
}
variable "sso_config" {
  type = object({
    enabled    = bool
    role       = string
    region     = string
    start_url  = string
  })
  description = "SSO Configuration"
}