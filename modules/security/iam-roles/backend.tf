terraform {

  required_providers {

    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


  backend "s3" {
    bucket         = "terraform-state-security-infinitydataservices-com"
    key            = "terrafrom-state/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}