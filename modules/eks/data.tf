
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_partition" "current" {}
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-dev-01"
    key            = "modules/vpc/terraform.tfstate"
    region = "eu-north-1"
    encrypt    = true
    kms_key_id     = "arn:aws:kms:eu-north-1:891377107274:key/e16b4178-7296-49f6-9cff-2fc61c2d474d"

  }
}

locals  {
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks


}