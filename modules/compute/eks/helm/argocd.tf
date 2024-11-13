





resource "aws_acm_certificate" "own_acm_argocd" {
  domain_name               = "argo.production.${var.public_dns_name}"
  subject_alternative_names = ["*.production.${var.public_dns_name}", "production.${var.public_dns_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "selected" {
  zone_id = var.r53_hosted_zone_id
  name         = var.public_dns_name
  private_zone = false
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

resource "helm_release" "argocd" {   ###############This resource is who create the load balancer in ec2 aws
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.6.4"

  values = [
    #file("values/argocd.yaml"),
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout" = "60"
            "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
            "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-subnets"         = "subnet-018b41dec416c9d3c,subnet-01158c8897a13ec73"
            "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"        = aws_acm_certificate.own_acm_argocd.arn
            "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"       = "443"
            "external-dns.alpha.kubernetes.io/hostname"                    = "argo.production.infinitydataservices.com"
            "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
            "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"
            #"alb.ingress.kubernetes.io/listen-ports"                       = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            #"alb.ingress.kubernetes.io/actions.ssl-redirect"               = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
          }
        }
        extraArgs = [
          "--insecure"
        ]
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]


  timeout = 300

  depends_on = [helm_release.aws_load_balancer_controller, aws_acm_certificate_validation.cert_validation, aws_acm_certificate.own_acm_argocd,null_resource.wait_for_cert_validation]
}

resource "null_resource" "wait_for_lb" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --namespace argocd \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=argocd-server \
        --timeout=300s
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
    "kubernetes.io/cluster/EKS-ArgoCD-01" = "owned"
    "kubernetes.io/service-name" = "argocd/argocd-server"
  }
  depends_on = [helm_release.argocd, data.kubernetes_service.argocd_server]

}

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argo.production.${var.public_dns_name}"
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

  depends_on = [helm_release.argocd, data.kubernetes_service.argocd_server, aws_acm_certificate_validation.cert_validation, aws_iam_role_policy_attachment.aws_load_balancer_controller, data.aws_lb.argocd]
}

resource "aws_route53_health_check" "argocd" {
  fqdn              = "argo.production.${var.public_dns_name}"
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




