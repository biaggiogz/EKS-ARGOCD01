
resource "kubernetes_namespace" "metric_server" {

  metadata {
    labels = local.labels
    name   = "metrics-server"
  }
}
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = kubernetes_namespace.metric_server.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.0"
  values     = [templatefile("${path.module}/helm-values/metrics-server.yaml", {})]
  depends_on = [kubernetes_namespace.metric_server]
}