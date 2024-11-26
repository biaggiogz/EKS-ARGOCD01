output "name_sa_spark_operator_dev" {
  value = kubernetes_service_account.sa_spark_operator_dev.metadata[0].name
}

output "jobNamespace_spark_operator_dev" {
  value = kubernetes_namespace.spark_operator_dev.metadata[0].name
}