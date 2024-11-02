terraform {
  backend "s3" {
    bucket         = "terraform-state-security-infinitydataservices-com"
    key            = "terrafrom-state/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}
