/*output "aws_efs_access_point_id-airflow-EKS-01" {
  value = aws_efs_access_point.airflow-EKS-01.id
}

output "rds_enpoint_airflow_postgres" {
  value = aws_db_instance.airflow-postgres-EKS-01.endpoint
  sensitive = true

}

output "airflow_db_connection_string" {
  value = "postgresql://${aws_db_instance.airflow-postgres-EKS-01.username}:${aws_db_instance.airflow-postgres-EKS-01.password}@${aws_db_instance.airflow-postgres-EKS-01.endpoint}/${aws_db_instance.airflow-postgres-EKS-01.db_name}"
  sensitive = true
}

output "db_user_name_airflow" {
  value       = aws_db_instance.airflow-postgres-EKS-01.username
}
*/

output "airflow_db_user" {
  value = module.db.db_instance_username
}


output "airflow_db_host" {
  value = module.db.db_instance_endpoint
  sensitive = true
}

output "airflow_db_name" {
  value = module.db.db_instance_name
  sensitive = true
}