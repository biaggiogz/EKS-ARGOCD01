
variable "PASSARCOGCD" {
  type = string
}

resource "aws_secretsmanager_secret" "argocd_credentials" {
  name = "argocd-credential-admin"
  recovery_window_in_days = 7

}

resource "aws_secretsmanager_secret_version" "argocd_credentials" {
  secret_id     = aws_secretsmanager_secret.argocd_credentials.id
  secret_string =  var.PASSARCOGCD
 # secret_string = jsonencode({
  #  username = "admin"
   # password = var.PASSARCOGCD
  #})
}


resource "aws_acm_certificate" "own_acm_argocd" {
  domain_name               = "argo.production.${local.public_dns_name}"
  subject_alternative_names = ["*.production.${local.public_dns_name}", "production.${local.public_dns_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.own_acm_argocd.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id


  depends_on = [aws_acm_certificate.own_acm_argocd]

}

resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.own_acm_argocd.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]

  depends_on = [aws_route53_record.cert_validation_record]
}

resource "null_resource" "wait_for_cert_validation" {
  depends_on = [aws_acm_certificate_validation.cert_validation]

  provisioner "local-exec" {
    command = "sleep 60"
  }
}
resource "kubernetes_namespace" "argocd" {

  metadata {
    labels = local.labels
    name   = "argocd"
  }
}
resource "kubernetes_namespace" "argo-events" {

  metadata {
    labels = local.labels
    name   = "argo-events"
  }
}
resource "kubernetes_service_account" "argocd_secrets_sa" {
  metadata {
    name      = "argocd-secrets-sa"
    namespace = "argocd"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.terraform_remote_state.eks.outputs.eks_secrets_manager_role-arn
    }
  }
}


resource "helm_release" "argocd" {   ###############This resource is who create the load balancer in ec2 aws
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = false
  version          = "7.6.4"

  values = [ templatefile("${path.module}/helm-values/argocd-values.yaml",{

    own_acm_argocd_arn = aws_acm_certificate.own_acm_argocd.arn
    public_subnets = join(",", data.terraform_remote_state.vpc.outputs.public_subnets)
    admin_password = aws_secretsmanager_secret_version.argocd_credentials.secret_string
    })
  ]


  timeout = 120

  depends_on = [kubernetes_service_account.argocd_secrets_sa, aws_acm_certificate_validation.cert_validation, aws_acm_certificate.own_acm_argocd,null_resource.wait_for_cert_validation, aws_secretsmanager_secret_version.argocd_credentials]
}

/*
resource "null_resource" "delete_secret_argocd" {
  #  kubectl patch secret argocd-secret -n argocd -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
  #      kubectl delete pods -n argocd -l app.kubernetes.io/name=argocd-server
  provisioner "local-exec" {
    command = <<EOT
      kubectl rollout restart deployment argocd-server -n argocd
      export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
      export ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
      argocd login $ARGOCD_SERVER --username admin --password $ADMIN_PASSWORD --insecure
      argocd account update-password --account admin --current-password $ADMIN_PASSWORD --new-password ${aws_secretsmanager_secret_version.argocd_credentials.secret_string}
    EOT
  }
  depends_on = [helm_release.argocd]
}
*/
/*
resource "kubernetes_secret" "argocd_secret_patch" {
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"
  }

  data = {
    "admin.password"      = bcrypt(aws_secretsmanager_secret_version.argocd_credentials.secret_string)
    "admin.passwordMtime" = timestamp()
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [
      data["admin.passwordMtime"]
    ]
  }
  depends_on = [helm_release.argocd, aws_secretsmanager_secret_version.argocd_credentials, null_resource.delete_secret_argocd]
}
resource "null_resource" "rollout_secret_argocd" {

  provisioner "local-exec" {

    command = <<EOT
      kubectl rollout restart deployment argocd-server -n argocd
    EOT
  }
}
*/

resource "null_resource" "wait_for_lb" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --namespace argocd \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=argocd-server \
        --timeout=60s
    EOT
  }
}


data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [null_resource.wait_for_lb]

}

data "aws_lb" "argocd" {
  tags = {
    "elbv2.k8s.aws/cluster" = data.terraform_remote_state.global-variables.outputs.cluster_name
    "service.k8s.aws/resource" = "LoadBalancer"
    "service.k8s.aws/stack" = "argocd/argocd-server"
  }
  depends_on = [helm_release.argocd, data.kubernetes_service.argocd_server]

}

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argo.production.${local.public_dns_name}"
  type    = "A"
  weighted_routing_policy {
    weight = 100
  }

  set_identifier = "argocd"


  alias {
    name                   = data.aws_lb.argocd.dns_name
    zone_id                = data.aws_lb.argocd.zone_id
    evaluate_target_health = true
  }

  depends_on = [kubernetes_namespace.argocd,helm_release.argocd, data.kubernetes_service.argocd_server, aws_acm_certificate_validation.cert_validation, data.aws_lb.argocd]
}

resource "aws_route53_health_check" "argocd" {
  fqdn              = "argo.production.${local.public_dns_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "argocd-health-check"
  }
  depends_on = [aws_route53_record.argocd ]
}

resource "helm_release" "argo-events" {   #
  name             = "argo-events"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-events"
  namespace        = "argo-events"
  create_namespace = false
  version          = "2.4.7"

  values = [ templatefile("${path.module}/helm-values/argo-events-values.yaml",{

  })
  ]


  timeout = 120

  depends_on = [kubernetes_namespace.argo-events]
}


/*
resource "null_resource" "disable_local_admin_configmap" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl delete configmap argocd-cm -n argocd
    EOT
  }
  depends_on = [helm_release.argocd]
}


resource "kubernetes_config_map" "disable-local-admin-argocd" {
  metadata {
    name = "argocd-cm"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/part-of" : "argocd"
    }
  }
  data = {
    "admin.enabled" = "false"
  }
  depends_on = [null_resource.disable_local_admin_configmap]
}*/