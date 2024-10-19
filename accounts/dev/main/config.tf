
provider "aws" {
  region  = var.region
  profile = var.profile
}

terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

  }

  backend "s3" {
    bucket         = ""
    key            = "terraform-state/dev/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    #ms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"
    #dynamodb_table = "terraform-state-lock"
  }
}


