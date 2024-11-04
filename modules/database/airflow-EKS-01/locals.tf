locals {
  airflow_name = "airflow"
  password = data.terraform_remote_state.iam-rds-postgres.outputs.postgres_pass
  name = data.terraform_remote_state.global-variables.outputs.environment_name
  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  vpc_secondary_cidr_blocks = data.terraform_remote_state.vpc.outputs.vpc_secondary_cidr_blocks
}