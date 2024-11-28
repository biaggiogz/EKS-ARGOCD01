/*
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
        targetRevision = "1.0.1"
        helm = {
          releaseName = "karpenter"
          parameters = [
            /*{
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
            },
            {
              name = "privateCluster.enabled"
              value = true
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
    */
/*
resource "kubernetes_manifest" "argocd_spark_operator_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "spark-operator"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://kubeflow.github.io/spark-operator"
        chart          = "spark-operator"
        targetRevision = "2.0.2"
        helm = {
          releaseName = "spark-operator"
          parameters = [
            {
              name  = "spark.jobNamespaces[0]"
              value = "spark-team-dev"
            }
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "spark-operator"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true", "ServerSideApply=true"]
      }
    }
  }
}
*/
/*
resource "kubernetes_manifest" "argocd_application_spark_test" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "spark-application"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "git@github.com:biaggiogz/EKS-ARGOCD01.git"
        targetRevision = "production-01"
        path           = "tests/integration"
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "spark-team-dev"
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
*/
