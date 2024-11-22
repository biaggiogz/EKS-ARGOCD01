output "enpoint_prometheus" {
  value =  aws_prometheus_workspace.amp[0].prometheus_endpoint
  sensitive = true

}

output "pod_status_spark_operator" {
  value = data.external.get_pod_status.result
}

output "karpenter" {
  value = module.eks_blueprints_addons.karpenter
}