
resource "random_password" "postgres" {
  #count   = data.terraform_remote_state.global-variables.outputs.enable_airflow ? 1 : 0
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "postgres" {
  #count   = data.terraform_remote_state.global-variables.outputs.enable_airflow ? 1 : 0
  name                    = "postgres-eks-01"
  recovery_window_in_days = 7

}

resource "aws_secretsmanager_secret_version" "postgres" {
  #count   = data.terraform_remote_state.global-variables.outputs.enable_airflow ? 1 : 0
  secret_id     = aws_secretsmanager_secret.postgres.id
  secret_string = random_password.postgres.result
  depends_on = [aws_secretsmanager_secret.postgres]
}