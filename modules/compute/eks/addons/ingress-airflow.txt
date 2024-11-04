resource "kubernetes_ingress_v1" "airflow_ingress" {
  metadata {
    name = "airflow-ingress"
    namespace = "airflow"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    tls {
      hosts = ["airflow.production.infinitydataservices.com"]
      secret_name = "airflow-tls-secret"
    }

    rule {
      host = "airflow.production.infinitydataservices.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "airflow-webserver"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

resource "null_resource" "wait_for_lb" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --namespace aiflow \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=airflow-webserver \
        --timeout=300s
    EOT
  }
}
data "kubernetes_service" "airflow_server" {
  metadata {
    name      = "airflow-webserver"
    namespace = "airflow"
  }
  depends_on = [null_resource.wait_for_lb]

}
resource "aws_route53_record" "airflow" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "airflow.production.infinitydataservices.com"
  type    = "A"
  weighted_routing_policy {
    weight = 100
  }

  set_identifier = "airflow"


  alias {
    name                   = data.aws_lb.awslb.dns_name
    zone_id                = data.aws_lb.awslb.zone_id
    evaluate_target_health = true
  }

  depends_on = [data.kubernetes_service.airflow_server, aws_acm_certificate_validation.cert_validation, aws_iam_role_policy_attachment.aws_load_balancer_controller, data.aws_lb.awslb]
}


resource "aws_acm_certificate" "own_acm_airflow" {
  domain_name               = "airflow.production.${var.public_dns_name}"
  subject_alternative_names = ["*.production.${var.public_dns_name}", "production.${var.public_dns_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.own_acm_airflow.domain_validation_options : dvo.domain_name => {
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


  depends_on = [aws_acm_certificate.own_acm_airflow]

}

resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.own_acm_airflow.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]

  depends_on = [aws_route53_record.cert_validation_record]
}



resource "aws_route53_health_check" "airflow" {
  fqdn              = "airflow.production.${var.public_dns_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "airflow-health-check"
  }
  depends_on = [aws_route53_record.airflow ]
}





data "aws_lb" "awslb" {
  tags = {
    "kubernetes.io/cluster/EKS-ArgoCD-01" = "owned"
    "kubernetes.io/service-name" = "airflow/airflow-webserver"
  }
  depends_on = [data.kubernetes_service.airflow_server]

}

