
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "terraform-state-compute-infinitydataservices-com"
    key    = "terrafrom-state/eks-production-01/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

data "terraform_remote_state" "networking-SG-airflow-EKS-01" {
  backend = "s3"

  config = {
    bucket   = "terraform-state-networking-infinitydataservices-com"
    key     = "terrafrom-state/security_groups/airflow-EKS-01/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
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







