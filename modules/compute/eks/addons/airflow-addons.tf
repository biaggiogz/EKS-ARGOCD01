module "eks_data_addons" {
  source  = "aws-ia/eks-data-addons/aws"
  version = ">=1.33.0" # ensure to update this to the latest/desired version

  oidc_provider_arn = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
  #---------------------------------------------------------------
  # Airflow Add-on
  #---------------------------------------------------------------
  enable_airflow = true
  airflow_helm_config = {
    namespace = local.airflow_namespace
    version   = "1.11.0"
    values = [templatefile("${path.module}/helm-values/airflow-values.yaml", {

      airflow_db_user = local.airflow_name
      airflow_db_pass = try(sensitive(aws_secretsmanager_secret_version.postgres[0].secret_string), "")
      airflow_db_name = try(module.db[0].db_instance_name, "")
      airflow_db_host = try(element(split(":", module.db[0].db_instance_endpoint), 0), "")
      airflow_db_host = data.terraform_remote_state.storage-airflow.outputs.rds_enpoint_airflow_postgres
      #Service Accounts
      worker_service_account    = try(kubernetes_service_account_v1.airflow_worker.metadata[0].name, local.airflow_workers_service_account)
      scheduler_service_account = try(kubernetes_service_account_v1.airflow_scheduler.metadata[0].name, local.airflow_scheduler_service_account)
      webserver_service_account = try(kubernetes_service_account_v1.airflow_webserver.metadata[0].name, local.airflow_webserver_service_account)
      # S3 bucket config for Logs
      s3_bucket_name        = try(module.airflow_s3_bucket[0].s3_bucket_id, "")
      webserver_secret_name = local.airflow_webserver_secret_name
      efs_pvc               = local.efs_pvc
    })]
  }



}