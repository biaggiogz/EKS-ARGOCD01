locals {

  aws_load_balancer_controller-arn = data.terraform_remote_state.eks.outputs.aws_load_balancer_controller-arn
  cluster_name =data.terraform_remote_state.eks.outputs.cluster_name
  public_dns_name =data.terraform_remote_state.global-variables.outputs.public_dns_name
  r53_hosted_zone_id =data.terraform_remote_state.global-variables.outputs.r53_hosted_zone_id
  cluster_endpoint =data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_version = data.terraform_remote_state.eks.outputs.cluster_version
  eks_oidc_provider_arn = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
  name = data.terraform_remote_state.global-variables.outputs.environment_name
  enable_amazon_prometheus =data.terraform_remote_state.global-variables.outputs.enable_amazon_prometheus
  #argocd_credentials = jsondecode(data.aws_secretsmanager_secret_version.argocd_credentials.secret_string)
  amp_ingest_service_account = "amp-iamproxy-ingest-service-account"
  amp_namespace              = "kube-prometheus-stack"
  policy_grafana_arn = data.terraform_remote_state.eks.outputs.policy_grafana_arn
  status_eks = data.terraform_remote_state.eks.outputs.status_eks
  #create_karpenter = data.terraform_remote_state.global-variables.outputs.create_karpenter
  #enable_karpenter = local.create_karpenter && (length(data.aws_eks_addon.karpenter) == 0 || data.aws_eks_addon.karpenter[0].id == null)
  region = data.aws_region.current.name
  admin_password_version_grafana =data.terraform_remote_state.eks.outputs.admin_password_version_grafana
  spark_team_namespace_created = data.terraform_remote_state.eks.outputs.spark_team_namespace_created
  namespace_spark_operator = "spark-operator"
  label_spark_operator ="app.kubernetes.io/name=spark-operator"



  labels = {
    environment                    = data.terraform_remote_state.global-variables.outputs.environment_name
    "app.kubernetes.io/managed-by"  = "Terraform"
    "app.kubernetes.io/part-of"   = data.terraform_remote_state.global-variables.outputs.environment_name
  }
  tags = {
    Blueprint  = local.name
  }

  tags_list = [
    for k, v in local.labels : "${k}=${v}"
  ]



}

