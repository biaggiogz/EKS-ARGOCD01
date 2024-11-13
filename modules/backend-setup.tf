terraform {
  backend "s3" {
    bucket         = "terraform-state-infinitydataservices-com"
    key            = "ArchitectElevatorAWS/production-01/modules/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"
    #dynamodb_table = "terraform-state-lock"
  }
}


provider "aws" {
  region = "eu-north-1"
}

locals { # Replace with your desired environment name
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
  bucket = "terraform-state-${var.environment_name}"
  force_destroy = true

  /*lifecycle {
    prevent_destroy = true
  }*/

  tags = {
    Name        = "Terraform State"
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "module_folders" {
  for_each = toset(local.modules)

  bucket = aws_s3_bucket.terraform_state.id
  key    = "modules/${each.key}/"
  content_type = "application/x-directory"
}
/*
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

output "module_state_keys" {
  value = {
    for module in local.modules :
    module => "${module}/terraform.tfstate"
  }
}

*/
