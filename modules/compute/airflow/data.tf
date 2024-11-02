
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "terraform-state-networking-infinitydataservices-com"
    key    = "terrafrom-state/eks-production-01/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

