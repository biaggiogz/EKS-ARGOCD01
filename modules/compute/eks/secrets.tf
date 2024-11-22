data "aws_secretsmanager_secret_version" "admin_password_version_grafana" {
  secret_id  = aws_secretsmanager_secret.grafana.id
  depends_on = [aws_secretsmanager_secret_version.grafana]
}

resource "random_password" "grafana" {
  length           = 16
  special          = true
  override_special = "@_"
}

resource "aws_secretsmanager_secret" "grafana" {
  name                    = "${local.name}-grafana"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id     = aws_secretsmanager_secret.grafana.id
  secret_string = random_password.grafana.result
}
/*
resource "kubernetes_secret" "event_sa" {
  metadata {
    name      = "${local.event_service_account}-secret"
    namespace = local.event_namespace
    annotations = {
      "kubernetes.io/service-account.name"      = kubernetes_service_account.event_sa.metadata.name
      "kubernetes.io/service-account.namespace" = local.event_namespace
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account.event_sa]
}*/