resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version          = "4.11.2"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  set {
    name  = "controller.config.enable-real-ip"
    value = "true"
  }

}