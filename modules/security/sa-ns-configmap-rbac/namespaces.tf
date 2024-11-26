

resource "kubernetes_namespace" "spark_operator_dev" {
  metadata {
    name = "spark-operator-dev"
  }
}
/*
resource "kubernetes_namespace" "spark-apps" {
  metadata {
    name = "spark-apps"
  }
}*/
##############################################################################