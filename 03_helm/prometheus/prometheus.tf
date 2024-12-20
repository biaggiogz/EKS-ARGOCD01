
locals {
  amp_namespace= "kube-prometheus-stack"
  amp_ingest_service_account= "amp-iamproxy-ingest-service-account"
  region = "eu-north-1"

}
resource "aws_iam_policy" "grafana" {

  description = "IAM policy for Grafana Pod"
  name_prefix = format("%s-%s-", var.cluster_name, "grafana")
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
    resources = ["arn:${var.partition}:cloudwatch:${local.region}:${var.account_id}:insight-rule/*"]

    actions = [
      "cloudwatch:GetInsightRuleReport",
    ]
  }

  statement {
    sid       = "AllowReadingAlarmHistoryFromCloudWatch"
    effect    = "Allow"
    resources = ["arn:${var.partition}:cloudwatch:${local.region}:${var.account_id}:alarm:*"]

    actions = [
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
    ]
  }

  statement {
    sid       = "AllowReadingLogsFromCloudWatch"
    effect    = "Allow"
    resources = ["arn:${var.partition}:logs:${local.region}:${var.account_id}:log-group:*:log-stream:*"]

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
      "arn:${var.partition}:aps:${local.region}:${var.account_id}:/*",
      "arn:${var.partition}:aps:${local.region}:${var.account_id}:workspace/*",
      "arn:${var.partition}:aps:${local.region}:${var.account_id}:workspace/*/*",
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


resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = local.amp_namespace
  }
}



resource "aws_secretsmanager_secret" "grafana" {
  name                    = "${var.cluster_name}-dash-grafana"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id     = aws_secretsmanager_secret.grafana.id
  secret_string = var.password_grafana
}/*
resource "aws_prometheus_workspace" "amp" {

  alias = format("%s-%s", "amp-ws", var.cluster_name)

}*/
resource "kubernetes_storage_class" "ebs_csi_encrypted_gp3_storage_class" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {

    fsType    = "xfs"
    encrypted = true
    type      = "gp3"
  }

}
module "eks_pod_identity_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix      = format("%s-%s-", var.cluster_name, "eks-pod-identity-agent")



  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:eks-pod-identity-agent"]
    }
  }

}
module "amp_ingest_irsa" {
  source         = "aws-ia/eks-blueprints-addon/aws"
  version        = "1.1.1"
  create_release = false
  create_role    = true
  create_policy  = false
  role_name      = format("%s-%s", var.cluster_name, "amp-ingest")
  role_policies  = { amp_policy = aws_iam_policy.grafana.arn , prometheusquery = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess",
    prometheuswrite = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"}

  oidc_providers = {
    this = {
      provider_arn    = var.eks_oidc_provider_arn
      namespace       = local.amp_namespace
      service_account = local.amp_ingest_service_account
    }
  }


}

resource "helm_release" "kube_prometheus_stack" {

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "kube-prometheus-stack"
  create_namespace = false

  version          = "66.2.0"

  values =  [templatefile("${path.module}/kube-prometheus.yaml", {
    region              = local.region
    amp_sa              = local.amp_ingest_service_account
    amp_irsa            = module.amp_ingest_irsa.iam_role_arn
    #amp_remotewrite_url = "https://aps-workspaces.${local.region}.amazonaws.com/workspaces/${aws_prometheus_workspace.amp.id}/api/v1/remote_write"
    #amp_url             = "https://aps-workspaces.${local.region}.amazonaws.com/workspaces/${aws_prometheus_workspace.amp.id}"
    storage_class_name  = kubernetes_storage_class.ebs_csi_encrypted_gp3_storage_class.metadata[0].name
    adminpassword = aws_secretsmanager_secret_version.grafana.secret_string
  })
  ]

  depends_on = [kubernetes_namespace.prometheus,aws_secretsmanager_secret_version.grafana]
}