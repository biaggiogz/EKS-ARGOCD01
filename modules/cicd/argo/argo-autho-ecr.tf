/*resource "kubernetes_secret" "argocd_ecr_secret" {
  metadata {
    name      = "ecr-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "helm"
    name     = "ecr-public"
    url      = "public.ecr.aws"
    username = data.aws_ecrpublic_authorization_token.token.user_name
    password = data.aws_ecrpublic_authorization_token.token.password
  }
}*/