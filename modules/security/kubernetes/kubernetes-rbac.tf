
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