output "grafana" {
  sensitive = true
  value = aws_secretsmanager_secret_version.grafana.secret_string
}