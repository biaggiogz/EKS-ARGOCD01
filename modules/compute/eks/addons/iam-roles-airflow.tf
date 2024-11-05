

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

resource "null_resource" "check_secret_deployment" {

  provisioner "local-exec" {
    command = <<-EOT
      kubectl get secret ${kubernetes_secret.airflow_webserver.metadata[0].name} -n ${kubernetes_secret.airflow_webserver.metadata[0].namespace} -o json | jq -r '.metadata.name'
    EOT
  }
  depends_on = [kubernetes_secret.airflow_webserver]

}

#---------------------------------------------------------------
# Persistent Volume Claim for EFS
#---------------------------------------------------------------

resource "kubernetes_storage_class" "efs" {
  metadata {
    name = local.efs_storage_class
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.efs.id
    directoryPerms   = "700"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
  }

  depends_on = [aws_efs_file_system.efs]
}


resource "kubernetes_persistent_volume_claim" "efs" {
  metadata {
    name      = local.efs_pvc
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = local.efs_storage_class

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  depends_on = [kubernetes_storage_class.efs, kubernetes_namespace_v1.airflow]
}
#---------------------------------------------------------------
# EFS Filesystem for Airflow DAGs
#---------------------------------------------------------------
resource "aws_efs_file_system" "efs" {
  creation_token = "efs"
  encrypted      = true

  tags = local.tags
}
variable "eks_data_plane_subnet_secondary_cidr" {
  description = "Secondary CIDR blocks. 32766 IPs per Subnet per Subnet/AZ for EKS Node and Pods"
  default     = ["100.64.0.0/17", "100.64.128.0/17"]
  type        = list(string)
}
resource "aws_efs_mount_target" "efs_mt" {
  count = length(var.eks_data_plane_subnet_secondary_cidr)


  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = compact([for subnet_id, cidr_block in zipmap(local.private_subnets, local.private_subnets_cidr_blocks) : substr(cidr_block, 0, 4) == "100." ? subnet_id : null])[count.index]
  security_groups = [aws_security_group.efs.id]
  depends_on = [aws_efs_file_system.efs,aws_security_group.efs]
}

resource "aws_security_group" "efs" {
  name        = "${local.name}-efs"
  description = "Allow inbound NFS traffic from private subnets of the VPC"
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow NFS 2049/tcp"
    cidr_blocks = local.private_subnets_cidr_blocks
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }

  tags = local.tags
}
