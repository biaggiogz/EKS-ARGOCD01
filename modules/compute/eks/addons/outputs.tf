output "airflow_webserver_secret" {
  value     = aws_secretsmanager_secret_version.airflow_webserver.secret_string
  sensitive = true
}
output "own_acm_airflow" {
  value = aws_acm_certificate.own_acm_airflow.arn
  sensitive = true
}