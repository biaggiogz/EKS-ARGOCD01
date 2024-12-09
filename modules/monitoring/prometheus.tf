resource "aws_prometheus_workspace" "amp" {
  #count = local.enable_amazon_prometheus ? 1 : 0

  alias = format("%s-%s", "amp-ws", local.cluster_name)
  tags  = local.tags
}

resource "aws_iam_policy" "grafana" {

  description = "IAM policy for Grafana Pod"
  name_prefix = format("%s-%s-", local.cluster_name, "grafana")
  path        = "/"
  policy      = data.aws_iam_policy_document.grafana.json
}


data "aws_iam_policy_document" "grafana" {

  statement {
    sid       = "AllowReadingMetricsFromCloudWatch"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics"
    ]
  }

  statement {
    sid       = "AllowGetInsightsCloudWatch"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:cloudwatch:${local.region}:${data.aws_caller_identity.current.account_id}:insight-rule/*"]

    actions = [
      "cloudwatch:GetInsightRuleReport",
    ]
  }

  statement {
    sid       = "AllowReadingAlarmHistoryFromCloudWatch"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:cloudwatch:${local.region}:${data.aws_caller_identity.current.account_id}:alarm:*"]

    actions = [
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
    ]
  }

  statement {
    sid       = "AllowReadingLogsFromCloudWatch"
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"]

    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents",
    ]
  }

  statement {
    sid       = "AllowReadingTagsInstancesRegionsFromEC2"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]
  }

  statement {
    sid       = "AllowReadingResourcesForTags"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["tag:GetResources"]
  }

  statement {
    sid    = "AllowListApsWorkspaces"
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.current.partition}:aps:${local.region}:${data.aws_caller_identity.current.account_id}:/*",
      "arn:${data.aws_partition.current.partition}:aps:${local.region}:${data.aws_caller_identity.current.account_id}:workspace/*",
      "arn:${data.aws_partition.current.partition}:aps:${local.region}:${data.aws_caller_identity.current.account_id}:workspace/*/*",
    ]
    actions = [
      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
      "aps:GetMetricMetadata",
      "aps:GetSeries",
      "aps:QueryMetrics",
      "aps:RemoteWrite",
      "aps:GetLabels"
    ]
  }
}
resource "aws_iam_role" "amp_ingest_role" {
  name = format("%s-%s", local.cluster_name, "amp-ingest")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.cluster_oidc_issuer_url, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(local.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:${local.amp_namespace}:${local.amp_ingest_service_account}"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "amp_ingest_policy_attachment" {
  role       = aws_iam_role.amp_ingest_role.name
  policy_arn = aws_iam_policy.grafana.arn
}

resource "aws_iam_role_policy_attachment" "prometheus_query_attachment" {
  role       = aws_iam_role.amp_ingest_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_iam_role_policy_attachment" "prometheus_write_attachment" {
  role       = aws_iam_role.amp_ingest_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

resource "kubernetes_annotations" "gp2_default" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  force = true

}

resource "kubernetes_storage_class" "prometheus_storage_class" {
  metadata {
    name = "prometheus-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }
}



resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "kube-prometheus-stack"
  }
}
resource "aws_secretsmanager_secret" "grafana" {
  name                    = "${local.cluster_name}-grafana"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id     = aws_secretsmanager_secret.grafana.id
  secret_string = var.secret_grafana
}



resource "helm_release" "kube_prometheus_stack" {

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "kube-prometheus-stack"
  create_namespace = false

  version          = "66.2.0"

  values = [templatefile("values/kube-prometheus.yaml", {
    region              = local.region
    amp_sa              = local.amp_ingest_service_account
    amp_irsa            = aws_iam_role.amp_ingest_role.arn
    amp_remotewrite_url = "https://aps-workspaces.${local.region}.amazonaws.com/workspaces/${aws_prometheus_workspace.amp.id}/api/v1/remote_write"
    amp_url             = "https://aps-workspaces.${local.region}.amazonaws.com/workspaces/${aws_prometheus_workspace.amp.id}"
    storage_class_name  = kubernetes_storage_class.prometheus_storage_class.metadata[0].name
    admin_password_version_grafana = aws_secretsmanager_secret_version.grafana.secret_string
  })
  ]

  depends_on = [kubernetes_storage_class.prometheus_storage_class, kubernetes_namespace.prometheus,aws_secretsmanager_secret_version.grafana]
}














/*data "aws_secretsmanager_secret_version" "admin_password_version" {
  secret_id  = aws_secretsmanager_secret.grafana.id
  depends_on = [aws_secretsmanager_secret_version.grafana]
}

resource "random_password" "grafana" {
  length           = 16
  special          = true
  override_special = "@_"
}
*/
#tfsec:ignore:aws-ssm-secret-use-customer-key
