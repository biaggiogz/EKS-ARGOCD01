module "spark_team_irsa" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create_release = false

  create_role   = true
  role_name     = "${local.name}-${local.spark_team}"
  create_policy = false
  role_policies = {
    spark_team_a_policy = aws_iam_policy.spark.arn
  }

  oidc_providers = {
    this = {
      provider_arn    = module.eks.oidc_provider_arn
      namespace       = local.spark_team
      service_account = local.spark_team
    }
  }
}

module "irsa_argo_events" {

  source         = "aws-ia/eks-blueprints-addon/aws"
  version        = "1.1.1"
  create_release = false
  create_policy  = false
  create_role    = true
  role_name      = "${local.name}-${local.event_namespace}"
  role_policies  = { policy_event = aws_iam_policy.sqs_argo_events.arn }

  oidc_providers = {
    this = {
      provider_arn    = module.eks.oidc_provider_arn
      namespace       = local.event_namespace
      service_account = local.event_service_account
    }
  }


  tags = local.tags
}