output "enpoint_prometheus" {
  value =  aws_prometheus_workspace.amp[0].prometheus_endpoint
  sensitive = true

}

output "pod_status_spark_operator" {
  value = data.external.get_pod_status.result
}

output "karpenter_role_arn" {
  value = module.eks_blueprints_addons.karpenter["iam_role_arn"]
}

output "karpenter_node_instance_profile_name" {
  value = module.eks_blueprints_addons.karpenter["node_instance_profile_name"]
}

output "karpenter_sqs_name" {
  value = module.eks_blueprints_addons.karpenter["sqs"]["queue_name"]
}

