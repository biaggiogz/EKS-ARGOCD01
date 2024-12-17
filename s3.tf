data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
resource "aws_kms_key" "ekskey" {
  description = format("EKS KMS Key 2 %s", "eks-03")
}
terraform {
  backend "s3" {
    bucket         = "tf-state-eks-03"
    key            = "eks-03/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    #kms_key_id     = aws_kms_key.ekskey.arn
    #dynamodb_table = "terraform-state-lock"
  }
}

resource "aws_s3_bucket" "terraform_state" {

  bucket = "tf-state-eks-03"

  force_destroy = true

  lifecycle {
    ignore_changes = [bucket]
  }

}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ekskey.key_id
    }
  }
}


resource "aws_s3_bucket_versioning" "terraform_state" {

  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "pub_block_state" {
  bucket = aws_s3_bucket.terraform_state.id

  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}

output "key_kms_s3_id" {
  value = aws_kms_key.ekskey.key_id
}
provider "aws" {
  region = "eu-north-1"
}
