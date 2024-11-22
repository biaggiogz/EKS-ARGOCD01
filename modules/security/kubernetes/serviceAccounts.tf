
resource "kubernetes_service_account" "operate_workflow_sa" {
  metadata {
    name      = "operate-workflow-sa"
    namespace = "argo-events"
  }
}
