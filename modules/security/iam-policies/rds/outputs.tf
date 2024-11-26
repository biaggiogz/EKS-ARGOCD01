

output "postgres_pass" {
  value = aws_secretsmanager_secret_version.postgres.secret_string
  sensitive = true
}