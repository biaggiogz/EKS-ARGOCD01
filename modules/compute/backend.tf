terraform {
  backend "s3" {
    bucket         = "terraform-state-compute-infinitydataservices-com"
    key            = "terrafrom-state/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}
