terraform {
  backend "s3" {
    bucket         = "terraform-state-infinitydataservices-com"
    key            = "terraform-state/EKS-ArgoCD-01/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"
    dynamodb_table = "shared-terraform-backend"
  }
}