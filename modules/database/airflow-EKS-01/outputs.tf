output "aws_efs_access_point_id-airflow-EKS-01" {
  value = aws_efs_access_point.airflow-EKS-01.id
}

output "rds_enpoint_airflow_postgres" {
  value = aws_db_instance.airflow-postgres-EKS-01.endpoint

}

output "airflow_db_connection_string" {
  value = "postgresql://${aws_db_instance.airflow-postgres-EKS-01.username}:${aws_db_instance.airflow-postgres-EKS-01.password}@${aws_db_instance.airflow-postgres-EKS-01.endpoint}/${aws_db_instance.airflow-postgres-EKS-01.db_name}"
  sensitive = true
}