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
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "tf-state-eks-03"
    key            = "vpc/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true

  }
}

provider "aws" {
  region = "eu-north-1"
}

locals {
  cluster_endpoint = module.outputs.cluster_endpoint
  cluster_version = module.outputs.cluster_version
  eks_oidc_provider_arn = module.outputs.eks_oidc_provider_arn
  cluster_oidc_issuer_url = module.outputs.cluster_oidc_issuer_url
  cluster_name = module.common_vars.cluster_name
  cluster_certificate_authority_data = module.outputs.cluster_certificate_authority_data
}
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}

provider "kubectl" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}
