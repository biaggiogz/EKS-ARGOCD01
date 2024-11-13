

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_partition" "current" {}

data "aws_iam_policy" "aws_load_balancer_controller" {
  name = "AWSLoadBalancerControllerIAMPolicy"
}



data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-production-01"
    key            = "modules/networking/vpc/terraform.tfstate"
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

/*
data "terraform_remote_state" "acm_certicate" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-compute-infinitydataservices-com"
    key            = "terrafrom-state/eks-production-01/addons/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}
*/
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

data "aws_route53_zone" "selected" {
  zone_id = local.r53_hosted_zone_id
  name         = local.public_dns_name
  private_zone = false
}
/*
data "aws_secretsmanager_secret_version" "argocd_credentials" {
  secret_id = aws_secretsmanager_secret.argocd_credentials.id
  depends_on = [aws_secretsmanager_secret_version.argocd_credentials]
}
*/