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
        targetRevision = "production-01"
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


resource "kubernetes_manifest" "argocd_karpenter_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "karpenter"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "public.ecr.aws/karpenter"
        chart          = "karpenter"
        targetRevision = "1.0.8"
        helm = {
          releaseName = "karpenter"
          parameters = [
            {
              name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
              value = local.karpenter_role_arn
            },
            {
              name  = "settings.aws.clusterName"
              value = local.cluster_name
            },
            {
              name  = "settings.aws.clusterEndpoint"
              value = local.cluster_endpoint
            }
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "karpenter"
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

resource "kubernetes_manifest" "argocd_application_karpenter" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "karpenter-nodespool"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "git@github.com:biaggiogz/EKS-ARGOCD01.git"
        targetRevision = "production-01"
        path           = "modules/cicd/argo/karpenter-manifest"
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "karpenter"
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