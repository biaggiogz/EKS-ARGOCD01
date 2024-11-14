output "argo-credentials" {
  value = aws_secretsmanager_secret_version.argocd_credentials.secret_string
  sensitive = true
}