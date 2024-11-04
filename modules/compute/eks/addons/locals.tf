locals {
  airflow_namespace = "airflow"
  airflow_scheduler_service_account = "airflow-scheduler"
  airflow_webserver_service_account = "airflow-webserver"
  airflow_workers_service_account   = "airflow-worker"
  airflow_webserver_secret_name     = "airflow-webserver-secret-key"
  efs_storage_class                 = "efs-sc"
  efs_pvc                           = "airflowdags-pvc"
  name = data.terraform_remote_state.global-variables.outputs.environment_name
  cluster_name = data.terraform_remote_state.global-variables.outputs.cluster_name
  private_subnets_cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets =data.terraform_remote_state.vpc.outputs.private_subnets
  tags = {
    Blueprint  = local.name
  }

}