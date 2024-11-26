/*
resource "kubernetes_service_account" "sa_spark_apps" {
  metadata {
    namespace = "spark-apps"
    name      = "spark"
  }
  depends_on = [kubernetes_namespace.spark-apps]
}*/

resource "kubernetes_service_account" "sa_spark_operator_dev" {
  metadata {
    name      = "sa-spark-operator-dev"
    namespace = kubernetes_namespace.spark_operator_dev.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = local.spark_operator_role_arn
    }
  }
  depends_on = [kubernetes_namespace.spark_operator_dev]
}
###########################################################################################
###########################################################################################
