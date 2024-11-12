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
      null = {
        source = "hashicorp/null"
        version = "3.2.3"
      }
    }
  backend "s3" {
    bucket         = "terraform-state-infinitydataservices-com"
    key            = "terraform-state-production-01/networking/vpc/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    kms_key_id     = env("TF_VAR_KMS_KEY_ID")

  }
}
