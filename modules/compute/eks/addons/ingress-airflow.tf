/*resource "kubernetes_ingress_v1" "airflow" {
  metadata {
    name      = "airflow-ingress"
    namespace = "airflow"
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate.own_acm_airflow.arn
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "alb.ingress.kubernetes.io/subnets"          = join(",", data.terraform_remote_state.vpc.outputs.public_subnets)
    }
  }

  spec {
    rule {
      host = "airflow.production.${var.public_dns_name}"
      http {
        path {
          path = "/"
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
  name = "k8s-airflow-airflowi-62f0e23a8c"
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
*/