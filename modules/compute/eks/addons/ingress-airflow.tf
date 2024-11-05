resource "aws_acm_certificate" "own_acm_airflow" {
  domain_name               = "airflow.production.${var.public_dns_name}"
  subject_alternative_names = ["*.production.${var.public_dns_name}", "production.${var.public_dns_name}"]
  validation_method         = "DNS"

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
  certificate_arn         = aws_acm_certificate.own_acm_airflow.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]

  depends_on = [aws_route53_record.cert_validation_record]

  timeouts {
    create = "5m"
  }
}


resource "kubernetes_ingress_v1" "airflow_ingress" {
  metadata {
    name = "airflow-ingress"
    namespace = "airflow"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {

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

  depends_on = [aws_acm_certificate_validation.cert_validation]
}


data "kubernetes_service" "airflow_server" {
  metadata {
    name      = "airflow-webserver"
    namespace = "airflow"
  }
}
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "kube-system"
  }
}

data "aws_lb" "nginx_ingress" {
  name = "k8s-kubesyst-nginxing-d02efc403d"
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
    name                   = data.aws_lb.nginx_ingress.dns_name
    zone_id                = data.aws_lb.nginx_ingress.zone_id
    evaluate_target_health = true
  }

  depends_on = [data.aws_lb.nginx_ingress, aws_acm_certificate_validation.cert_validation]
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

  depends_on = [aws_route53_record.airflow]
}

