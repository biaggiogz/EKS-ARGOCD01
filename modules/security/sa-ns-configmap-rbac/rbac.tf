
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["integration", "development"])

  metadata {
    name = each.key
  }
}

locals {
  roles = {
    dev = {
      namespace = "development"
      name      = "dev-role"
    }
    integ = {
      namespace = "integration"
      name      = "integ-role"
    }
  }
}

resource "kubernetes_role" "roles" {
  for_each = local.roles

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  rule {
    api_groups = ["", "apps", "batch", "extensions"]
    resources  = [
      "configmaps", "cronjobs", "deployments", "events", "ingresses",
      "jobs", "pods", "pods/attach", "pods/exec", "pods/log",
      "pods/portforward", "secrets", "services"
    ]
    verbs      = [
      "create", "delete", "describe", "get", "list", "patch", "update"
    ]
  }
}

resource "kubernetes_role_binding" "role_bindings" {
  for_each = local.roles

  metadata {
    name      = "${each.value.name}-binding"
    namespace = each.value.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = each.value.name
  }

  subject {
    kind = "User"
    name = "${each.key}-user"
  }
}
###########################################################################################
###########################################################################################
resource "kubernetes_cluster_role_binding" "spark-cluster-role-binding" {
  metadata {
    name = "spark-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.spark_operator_dev.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.sa_spark_operator_dev.metadata[0].name
    namespace = kubernetes_service_account.sa_spark_operator_dev.metadata[0].name
  }
  depends_on = [kubernetes_service_account.sa_spark_operator_dev, kubernetes_cluster_role.spark_operator_dev]
}

resource "kubernetes_cluster_role" "spark_operator_dev" {
  metadata {
    name = "spark-operator-dev"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "persistentvolumeclaims"]
    verbs      = ["*"]
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
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["sparkoperator.k8s.io"]
    resources  = ["sparkapplications", "scheduledsparkapplications"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["create", "get", "list", "watch"]
  }

  rule {
    verbs      = ["create", "patch", "delete", "watch"]
    api_groups = [""]
    resources  = ["secrets"]
  }
  rule {
    verbs      = ["get", "list", "watch", "describe", "create", "edit", "delete", "annotate", "patch", "label"]
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
  }
}