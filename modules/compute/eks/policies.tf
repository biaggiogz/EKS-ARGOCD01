resource "aws_iam_policy" "secrets_manager_access" {
  name        = "eks-secrets-manager-access"
  path        = "/"
  description = "IAM policy for accessing Secrets Manager from EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:argocd-*"
      }
    ]
  })
}

resource "aws_iam_policy" "grafana" {

  description = "IAM policy for Grafana Pod"
  name_prefix = format("%s-%s-", local.name, "grafana")
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
    resources = ["arn:${local.partition}:cloudwatch:${local.region}:${local.account_id}:insight-rule/*"]

    actions = [
      "cloudwatch:GetInsightRuleReport",
    ]
  }

  statement {
    sid       = "AllowReadingAlarmHistoryFromCloudWatch"
    effect    = "Allow"
    resources = ["arn:${local.partition}:cloudwatch:${local.region}:${local.account_id}:alarm:*"]

    actions = [
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
    ]
  }

  statement {
    sid       = "AllowReadingLogsFromCloudWatch"
    effect    = "Allow"
    resources = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:*:log-stream:*"]

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
      "arn:${local.partition}:aps:${local.region}:${local.account_id}:/*",
      "arn:${local.partition}:aps:${local.region}:${local.account_id}:workspace/*",
      "arn:${local.partition}:aps:${local.region}:${local.account_id}:workspace/*/*",
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


resource "aws_iam_policy" "kubecost_policy" {
  name        = "KubecostPolicy"
  path        = "/"
  description = "IAM policy for Kubecost"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:*",
          "glue:*",
          "s3:*",
          "s3-object-lambda:*",
          "cloudwatch:GetMetricData",
          "compute-optimizer:GetEnrollmentStatus",
          "compute-optimizer:GetRecommendationSummaries",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeReservedInstances",
          "ec2:DescribeReservedInstancesModifications",
          "ec2:DescribeReservedInstancesOfferings",
          "ec2:DescribeTags",
          "ecs:DescribeClusters",
          "ecs:DescribeContainerInstances",
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "organizations:DescribeOrganization",
          "ce:GetCostAndUsage",
          "ce:GetTags",
          "pricing:GetProducts",
          "savingsplans:DescribeSavingsPlans"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_policy" "spark" {
  description = "IAM role policy for Spark Job execution"
  name        = "${local.name}-spark-irsa"
  policy      = data.aws_iam_policy_document.spark_operator.json
}


resource "aws_iam_policy" "sqs_argo_events" {
  description = "IAM policy for Argo Events"
  name_prefix = format("%s-%s-", local.name, "argo-events")
  path        = "/"
  policy      = data.aws_iam_policy_document.sqs_argo_events.json
}
