resource "kubernetes_cluster_role" "spark_argowf_role" {
  metadata {
    name = "spark-op-role"
  }

  rule {
    verbs      = ["*"]
    api_groups = ["sparkoperator.k8s.io"]
    resources  = ["sparkapplications"]
  }
}





resource "kubernetes_role_binding" "admin_rolebinding_argoworkflows" {
  count = local.pod_status_spark_operator == "Running" ? 1: 0
  metadata {
    name      = "argo-workflows-admin-rolebinding"
    namespace = "argo-workflows"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "argo-workflows"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }

  #depends_on = [module.eks_blueprints_addons]
}



resource "kubernetes_role" "operate_workflow_role_events" {
  metadata {
    name      = "operate-workflow-role"
    namespace = "argo-events"
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["workflows", "workflowtemplates", "cronworkflows", "clusterworkflowtemplates"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "operate_workflow_role_binding_events" {
  metadata {
    name      = "operate-workflow-role-binding"
    namespace = "argo-events"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.operate_workflow_role_events.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.operate_workflow_sa.metadata[0].name
    namespace = "argo-events"
  }
}

resource "kubernetes_role" "operate_workflow_role_workflows" {
  metadata {
    name      = "operate-workflow-role"
    namespace = "argo-workflows"
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["workflows", "workflowtemplates", "cronworkflows", "clusterworkflowtemplates"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "operate_workflow_role_binding_workflows" {
  metadata {
    name      = "operate-workflow-role-binding"
    namespace = "argo-workflows"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.operate_workflow_role_workflows.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.operate_workflow_sa.metadata[0].name
    namespace = "argo-events"
  }
}