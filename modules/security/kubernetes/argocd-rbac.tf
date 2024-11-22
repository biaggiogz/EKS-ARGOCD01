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