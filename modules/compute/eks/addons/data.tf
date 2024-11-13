data "aws_partition" "current" {}



data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-compute-infinitydataservices-com"
    key            = "terrafrom-state/eks-production-01/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

data "terraform_remote_state" "storage-airflow" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-database-infinitydataservices-com"
    key            = "terrafrom-state/airflow-EKS-01/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

data "terraform_remote_state" "global-variables" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-infinitydataservices-com"
    key            = "ArchitectElevatorAWS/modules/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}


data "aws_route53_zone" "selected" {
  zone_id = var.r53_hosted_zone_id
  name         = var.public_dns_name
  private_zone = false
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "terraform-state-networking-infinitydataservices-com"
    key     = "terrafrom-state/vpc-production-01/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

data "terraform_remote_state" "postgres-secrets" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-security-infinitydataservices-com"
    key            = "terrafrom-state/iam-roles/rds/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 30
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.terraform_remote_state.eks.outputs.kubectl.token
}