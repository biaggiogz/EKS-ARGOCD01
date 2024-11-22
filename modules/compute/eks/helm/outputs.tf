output "argocd_url" {
  value     = data.external.url_argocd.result
  sensitive = true
}

output "admin_token" {
  value = aws_secretsmanager_secret_version.argocd_token.secret_string
  sensitive = true
}