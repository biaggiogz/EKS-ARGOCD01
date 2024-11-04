
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
  tags = {
    Blueprint  = local.name
  }

}
resource "kubernetes_namespace_v1" "airflow" {
  metadata {
    name = local.airflow_namespace
  }
}
module "airflow_irsa_scheduler" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0" # ensure to update this to the latest/desired version

  # IAM role for service account (IRSA)
  create_release = false
  create_policy  = false # Policy is created in the next resource

  create_role = true
  role_name   = local.airflow_scheduler_service_account

  role_policies = { AirflowScheduler = aws_iam_policy.airflow_scheduler.arn }

  oidc_providers = {
    this = {
      provider_arn    = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
      namespace       = local.airflow_namespace
      service_account = local.airflow_scheduler_service_account
    }
  }
}

module "airflow_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "eks-01-airflow-logs-"

  # For example only - please evaluate for your environment
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

}



resource "kubernetes_secret_v1" "airflow_worker" {
  metadata {
    name      = "${local.airflow_workers_service_account}-secret"
    namespace = local.airflow_namespace
    annotations = {
      "kubernetes.io/service-account.name"      = kubernetes_service_account_v1.airflow_worker.metadata[0].name
      "kubernetes.io/service-account.namespace" = local.airflow_namespace
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account_v1.airflow_scheduler]
}
resource "kubernetes_service_account_v1" "airflow_worker" {
  metadata {
    name        = local.airflow_workers_service_account
    namespace   = local.airflow_namespace
    annotations = { "eks.amazonaws.com/role-arn" : module.airflow_irsa_worker.iam_role_arn }
  }

  automount_service_account_token = true

  depends_on = [module.airflow_irsa_worker]
}



resource "kubernetes_service_account_v1" "airflow_scheduler" {
  metadata {
    name        = local.airflow_scheduler_service_account
    namespace   = local.airflow_namespace
    annotations = { "eks.amazonaws.com/role-arn" : module.airflow_irsa_scheduler.iam_role_arn }
  }

  automount_service_account_token = true

  depends_on = [module.airflow_irsa_scheduler]
}

resource "kubernetes_secret_v1" "airflow_scheduler" {
  metadata {
    name      = "${kubernetes_service_account_v1.airflow_scheduler.metadata[0].name}-secret"
    namespace = local.airflow_namespace
    annotations = {
      "kubernetes.io/service-account.name"      = kubernetes_service_account_v1.airflow_scheduler.metadata[0].name
      "kubernetes.io/service-account.namespace" = local.airflow_namespace
    }
  }


  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account_v1.airflow_scheduler]
}

resource "aws_iam_policy" "airflow_worker" {

  description = "IAM policy for Airflow Workers Pod"
  name_prefix = local.airflow_workers_service_account
  path        = "/"
  policy      = data.aws_iam_policy_document.airflow_s3_logs.json

  depends_on = [data.aws_iam_policy_document.airflow_s3_logs]
}

data "aws_iam_policy_document" "airflow_s3_logs" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${module.airflow_s3_bucket.s3_bucket_id}"]

    actions = [
      "s3:ListBucket"
    ]
  }
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${module.airflow_s3_bucket.s3_bucket_id}/*"]

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
  }
}

module "airflow_irsa_worker" {

  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  # Disable helm release
  create_release = false

  # IAM role for service account (IRSA)
  create_role   = true
  create_policy = false # Policy is created in the next resource

  role_name     = local.airflow_workers_service_account
  role_policies = merge({ AirflowWorker = aws_iam_policy.airflow_worker.arn })

  oidc_providers = {
    this = {
      provider_arn    = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
      namespace       = local.airflow_namespace
      service_account = local.airflow_workers_service_account
    }
  }

}



resource "aws_iam_policy" "airflow_scheduler" {

  description = "IAM policy for Airflow Scheduler Pod"
  name_prefix = local.airflow_scheduler_service_account
  path        = "/"
  policy      = data.aws_iam_policy_document.airflow_s3_logs.json
}

resource "kubernetes_service_account_v1" "airflow_webserver" {

  metadata {
    name = "airflow-webserver"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" : module.airflow_irsa_webserver.iam_role_arn
    }
  }
  automount_service_account_token = true


}

resource "kubernetes_secret_v1" "airflow_webserver" {
  metadata {
    name      = "${kubernetes_service_account_v1.airflow_webserver.metadata[0].name}-secret"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name"      = kubernetes_service_account_v1.airflow_webserver.metadata[0].name
      "kubernetes.io/service-account.namespace" = kubernetes_namespace_v1.airflow.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

module "airflow_irsa_webserver" {

  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  # Disable helm release
  create_release = false

  # IAM role for service account (IRSA)
  create_role   = true
  create_policy = false # Policy is created in the next resource

  role_name     = local.airflow_webserver_service_account
  role_policies = merge({ AirflowWebserver = aws_iam_policy.airflow_webserver.arn })

  oidc_providers = {
    this = {
      provider_arn    = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
      namespace       = kubernetes_namespace_v1.airflow.metadata[0].name
      service_account = local.airflow_webserver_service_account
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "airflow_webserver" {

  description = "IAM policy for Airflow Webserver Pod"
  name_prefix = local.airflow_webserver_service_account
  path        = "/"
  policy      = data.aws_iam_policy_document.airflow_s3_logs.json
}

#---------------------------------------------------------------
# Apache Airflow Webserver Secret
#---------------------------------------------------------------
resource "random_id" "airflow_webserver" {
  byte_length = 16
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "airflow_webserver" {
  name                    = "airflow_webserver_secret_key_2"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy

}

resource "aws_secretsmanager_secret_version" "airflow_webserver" {
  secret_id     = aws_secretsmanager_secret.airflow_webserver.id
  secret_string = random_id.airflow_webserver.hex
}

#---------------------------------------------------------------
# Webserver Secret Key
#---------------------------------------------------------------

resource "kubernetes_secret" "airflow_webserver" {
  metadata {
    name      = "airflow-webserver-secret-key"
    namespace = "airflow"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = "airflow"
      "meta.helm.sh/release-namespace" = "airflow"
    }
  }

  type = "Opaque"

  data = {
    "webserver-secret-key" = base64encode(aws_secretsmanager_secret_version.airflow_webserver.secret_string)
  }

  depends_on = [kubernetes_namespace_v1.airflow, aws_secretsmanager_secret_version.airflow_webserver]
}
/*resource "kubectl_manifest" "airflow_webserver" {
  sensitive_fields = [
    "data.webserver-secret-key"
  ]

  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
   name: "airflow-webserver-secret-key"
   namespace: "airflow"
   labels:
    app.kubernetes.io/managed-by: "Helm"
   annotations:
    meta.helm.sh/release-name: "airflow"
    meta.helm.sh/release-namespace: "airflow"
type: Opaque
data:
  webserver-secret-key: ${base64encode(aws_secretsmanager_secret_version.airflow_webserver.secret_string)}
YAML

  depends_on = [kubernetes_namespace_v1.airflow,aws_secretsmanager_secret_version.airflow_webserver]
}*/
resource "null_resource" "check_secret_deployment" {

  provisioner "local-exec" {
    command = <<-EOT
      kubectl get secret ${kubernetes_secret.airflow_webserver.metadata[0].name} -n ${kubernetes_secret.airflow_webserver.metadata[0].namespace} -o json | jq -r '.metadata.name'
    EOT
  }
  depends_on = [kubernetes_secret.airflow_webserver]

}