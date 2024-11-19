locals {

  aws_load_balancer_controller-arn = data.terraform_remote_state.eks.outputs.aws_load_balancer_controller-arn
  cluster_name =data.terraform_remote_state.eks.outputs.cluster_name
  public_dns_name =data.terraform_remote_state.global-variables.outputs.public_dns_name
  r53_hosted_zone_id =data.terraform_remote_state.global-variables.outputs.r53_hosted_zone_id
  cluster_oidc_issuer_url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
  cluster_endpoint = data.terraform_remote_state.eks.outputs.cluster_endpoint
  #argocd_credentials = jsondecode(data.aws_secretsmanager_secret_version.argocd_credentials.secret_string)

  labels = {
    "environment"                    = data.terraform_remote_state.global-variables.outputs.environment_name
    "app.kubernetes.io/managed-by" = "Terraform"
    "app.kubernetes.io/part-of"    = data.terraform_remote_state.global-variables.outputs.environment_name
  }

  tags_list = [
    for k, v in local.labels : "${k}=${v}"
  ]



}