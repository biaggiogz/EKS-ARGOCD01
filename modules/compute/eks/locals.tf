locals {
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  private_subnets_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  region = data.terraform_remote_state.global-variables.outputs.region
  name = data.terraform_remote_state.global-variables.outputs.environment_name
  cluster_name = data.terraform_remote_state.global-variables.outputs.cluster_name
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id
  public_dns_name =data.terraform_remote_state.global-variables.outputs.public_dns_name
  r53_hosted_zone_id =data.terraform_remote_state.global-variables.outputs.r53_hosted_zone_id
  spark_team = data.terraform_remote_state.global-variables.outputs.spark_team
  event_namespace       = "argo-events"
  event_service_account = "event-sa"
  pod_status_spark_operator = data.terraform_remote_state.eks_addons.outputs.pod_status_spark_operator

  labels = {
    environment                    = data.terraform_remote_state.global-variables.outputs.environment_name
    "app.kubernetes.io/managed-by"  = "Terraform"
    "app.kubernetes.io/part-of"   = data.terraform_remote_state.global-variables.outputs.environment_name
  }
  tags = {
    Blueprint  = local.name
  }
}