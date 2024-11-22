locals {
  spark_team = data.terraform_remote_state.global-variables.outputs.spark_team
  spark_team_irsa_created = data.terraform_remote_state.eks.outputs.spark_team_irsa_created
  spark_team_namespace_created = data.terraform_remote_state.eks.outputs.spark_team_namespace_created
  pod_status_spark_operator = data.terraform_remote_state.eks_addons.outputs.pod_status_spark_operator
  karpenter_role_arn = data.terraform_remote_state.eks_addons.outputs.karpenter_role_arn
}