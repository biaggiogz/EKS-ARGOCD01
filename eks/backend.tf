terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.0"
    }
  }
  backend "s3" {
    bucket         = "tf-state-eks-03"
    key            = "eks/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true

  }
}

provider "aws" {
  region = "eu-north-1"
}
