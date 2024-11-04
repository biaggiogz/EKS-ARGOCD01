output "airflow_webserver_secret" {
  value     = aws_secretsmanager_secret_version.airflow_webserver.secret_string
  sensitive = true
}