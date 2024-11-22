resource "kubernetes_manifest" "argocd_application_events" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "argo-events-eventbus"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "git@github.com:biaggiogz/EKS-ARGOCD01.git"
        targetRevision = "production01"
        path           = "modules/cicd/argo/argo-events-manifest"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argo-events"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}