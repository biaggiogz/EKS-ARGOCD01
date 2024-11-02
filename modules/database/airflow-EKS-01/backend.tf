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
      version = "3.5.1"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.0.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-database-infinitydataservices-com"
    key            = "terrafrom-state/airflow-EKS-01/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}
