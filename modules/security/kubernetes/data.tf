data "terraform_remote_state" "global-variables" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-infinitydataservices-com"
    key            = "ArchitectElevatorAWS/production-01/modules/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}




data "terraform_remote_state" "eks_addons" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-production-01"
    key            = "modules/compute/eks/addons/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}


data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-production-01"
    key            = "modules/compute/eks/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}