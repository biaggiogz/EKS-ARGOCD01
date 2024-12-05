resource "kubernetes_namespace" "spark_team" {
  metadata {
    name = local.spark_team
  }
}
resource "kubernetes_namespace" "spark_operator" {
  metadata {
    name = "spark-operator"
  }
}

resource "kubernetes_service_account" "spark_team" {
  metadata {
    name        = local.spark_team
    namespace   = kubernetes_namespace.spark_team.metadata[0].name
    annotations = { "eks.amazonaws.com/role-arn" : module.spark_team_a_irsa.iam_role_arn }
  }

  automount_service_account_token = true

  depends_on = [kubernetes_namespace.spark_team]
}
resource "kubernetes_secret" "spark_team" {
  metadata {
    name      = "${local.spark_team}-secret"
    namespace = kubernetes_namespace.spark_team.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name"      = kubernetes_service_account.spark_team.metadata[0].name
      "kubernetes.io/service-account.namespace" = kubernetes_namespace.spark_team.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_namespace.spark_team, kubernetes_service_account.spark_team]

}
module "spark_team_a_irsa" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"

  # Disable helm release
  create_release = false

  # IAM role for service account (IRSA)
  create_role   = true
  role_name     = "EKS-01-${local.spark_team}"
  create_policy = false
  role_policies = {
    spark_team_a_policy = aws_iam_policy.spark.arn
  }

  oidc_providers = {
    this = {
      provider_arn    = local.eks_oidc_provider_arn
      namespace       = local.spark_team
      service_account = local.spark_team
    }
  }
}
resource "aws_iam_policy" "spark" {
  description = "IAM role policy for Spark Job execution"
  name        = "${local.cluster_name}irsa-${local.spark_team}"
  policy      = data.aws_iam_policy_document.spark_operator.json
}
data "aws_iam_policy_document" "spark_operator" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:s3:::*"]

    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
  }
}

resource "kubernetes_cluster_role" "spark_role" {
  metadata {
    name = "spark-cluster-role"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["namespaces", "nodes", "persistentvolumes"]
  }

  rule {
    verbs      = ["list", "watch"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
  }
  rule {
    verbs      = ["get", "list", "watch", "describe", "create", "edit", "delete", "deletecollection", "annotate", "patch", "label"]
    api_groups = [""]
    resources  = ["serviceaccounts", "services", "configmaps", "events", "pods", "pods/log", "persistentvolumeclaims"]
  }

  rule {
    verbs      = ["create", "patch", "delete", "watch"]
    api_groups = [""]
    resources  = ["secrets"]
  }

  rule {
    verbs      = ["get", "list", "watch", "describe", "create", "edit", "delete", "annotate", "patch", "label"]
    api_groups = ["apps"]
    resources  = ["statefulsets", "deployments"]
  }

  rule {
    verbs      = ["get", "list", "watch", "describe", "create", "edit", "delete", "annotate", "patch", "label"]
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
  }


  rule {
    verbs      = ["get", "list", "watch", "describe", "create", "edit", "delete", "annotate", "patch", "label"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }

  rule {
    verbs      = ["get", "list", "watch", "describe", "create", "edit", "delete", "deletecollection", "annotate", "patch", "label"]
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings"]
  }

  depends_on = [module.spark_team_a_irsa]
}
#---------------------------------------------------------------
# Kubernetes Cluster Role binding role for service Account spark-team-dev
#---------------------------------------------------------------
resource "kubernetes_cluster_role_binding" "spark_role_binding" {
  metadata {
    name = "spark-cluster-role-bind"
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.spark_team
    namespace = local.spark_team
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.spark_role.id
  }

  depends_on = [module.spark_team_a_irsa]
}
/*
data "external" "existing_serviceaccount" {
  program = ["bash", "-c", <<EOT
    if kubectl get serviceaccount spark-operator-controller -n spark-operator > /dev/null 2>&1; then
      echo '{"exists": "true"}'
    else
      echo '{"exists": "false"}'
    fi
  EOT
  ]

  depends_on = [kubernetes_service_account.spark_team]
}
*/
resource "helm_release" "spark_operator" {
  //count = data.external.existing_serviceaccount.result.exists == "true" ? 0 : 1

  name             = "spark-operator"
  repository       = "https://kubeflow.github.io/spark-operator"
  chart            = "spark-operator"
  namespace        = "spark-operator"
  create_namespace = true

  version          = "2.0.2"

  values = [ templatefile("${path.module}/values/spark-operator.yaml",{
    })
  ]

  depends_on = [kubernetes_namespace.spark_operator]
}

#Use annotations in SparkApplication resources:
#metadata:
#  annotations:
#    yunikorn.apache.org/scheduler-name: yunikorn