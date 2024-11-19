resource "kubernetes_namespace" "metric_server" {

  metadata {
    labels = local.labels
    name   = "metrics-server"
  }
}

resource "kubernetes_namespace" "argocd" {

  metadata {
    labels = local.labels
    name   = "argocd"
  }

}

resource "kubernetes_namespace" "argo-events" {

  metadata {
    labels = local.labels
    name   = "argo-events"
  }
}
resource "kubernetes_namespace" "argo-workflows" {

  metadata {
    labels = local.labels
    name   = "argo-workflows"
  }
}




