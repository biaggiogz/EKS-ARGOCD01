output "argocd_url" {
  value     = aws_route53_record.argocd.name
  sensitive = true
}

output "admin_token" {
  value = aws_secretsmanager_secret_version.argocd_token.secret_string
  sensitive = true
}