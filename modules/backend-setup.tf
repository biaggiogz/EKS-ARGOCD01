provider "aws" {
  region = "eu-north-1"
}

locals {
  modules = [
    "networking",
    "compute",
    "database",
    "security",
    "monitoring",
    "shared-services"
  ]
}

resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(local.modules)

  bucket = "terraform-state-${each.key}-infinitydataservices-com"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State for ${each.key}"
   # Environment = "Management"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    #Environment = "Management"
    ManagedBy   = "Terraform"
  }
}

output "s3_bucket_names" {
  value = { for k, v in aws_s3_bucket.terraform_state : k => v.id }
}