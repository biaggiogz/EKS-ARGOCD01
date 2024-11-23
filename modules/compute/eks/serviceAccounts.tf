



resource "kubernetes_service_account" "kubecost" {
  metadata {
    name      = "kubecost-cost-analyzer"
    namespace = "kubecost"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kubecost_role.arn
    }
  }
  depends_on = [kubernetes_namespace.kubecost]
}

resource "kubernetes_service_account" "spark_team" {
  metadata {
    name        = local.spark_team
    namespace   = kubernetes_namespace.spark_team.metadata[0].name
    annotations = { "eks.amazonaws.com/role-arn" : module.spark_team_irsa.iam_role_arn }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace.spark_team , module.spark_team_irsa]
}


resource "kubernetes_service_account" "event_sa" {
  metadata {
    name        = local.event_service_account
    namespace   = kubernetes_namespace.argo-events.metadata[0].name
    annotations = { "eks.amazonaws.com/role-arn" : module.irsa_argo_events.iam_role_arn }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace.argo-events, module.irsa_argo_events]
}
