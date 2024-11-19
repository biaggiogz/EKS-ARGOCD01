/*
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
*/


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

    acm_certificate_arn = aws_acm_certificate.own_acm.arn
    public_subnets = join(",", data.terraform_remote_state.vpc.outputs.public_subnets)
    })
  ]


  timeout = 120

  depends_on = [kubernetes_service_account.argocd_secrets_sa, aws_acm_certificate_validation.cert_validation, aws_acm_certificate.own_acm,null_resource.wait_for_cert_validation]
}



resource "helm_release" "argo-workflows" {   #
  name             = "argo-workflows"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-workflows"
  namespace        = "argo-workflows"
  create_namespace = false
  version          = "0.42.6"

  values = [ templatefile("${path.module}/helm-values/argo-workflows-values.yaml",{

    acm_certificate_arn = aws_acm_certificate.own_acm.arn
    public_subnets = join(",", data.terraform_remote_state.vpc.outputs.public_subnets)

  })
  ]


  timeout = 120

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

}

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
    "elbv2.k8s.aws/cluster"= "EKS-01"
    "service.k8s.aws/stack" = "argocd/argocd-server"
  }
  depends_on = [helm_release.argocd, data.kubernetes_service.argocd_server]

}
data "aws_lb" "argo-workflows" {
  tags = {
    "kubernetes.io/cluster/EKS-01" = "owned"
    "kubernetes.io/service-name" =   "argo-workflows/argo-workflows-server"
  }

}

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argocd.dev.${local.public_dns_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.argocd.dns_name
    zone_id                = data.aws_lb.argocd.zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "argo-worflows" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argo-workflows.dev.${local.public_dns_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.argo-workflows.dns_name
    zone_id                = data.aws_lb.argo-workflows.zone_id
    evaluate_target_health = true
  }
}


resource "aws_route53_health_check" "argocd" {
  fqdn              = "dev.${local.public_dns_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "argocd-health-check"
  }
  depends_on = [aws_route53_record.argocd]
}

resource "aws_route53_health_check" "argo-worfklows" {
  fqdn              = "dev.${local.public_dns_name}"
  port              = 2746
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "argo-worflows-health-check"
  }
  depends_on = [aws_route53_record.argo-worflows]
}

resource "aws_acm_certificate" "own_acm" {
  domain_name               = "dev.${local.public_dns_name}"
  subject_alternative_names = ["*.dev.${local.public_dns_name}", "dev.${local.public_dns_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.own_acm.domain_validation_options : dvo.domain_name => {
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


  depends_on = [aws_acm_certificate.own_acm]

}

resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.own_acm.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]

  depends_on = [aws_route53_record.cert_validation_record]
}

resource "null_resource" "wait_for_cert_validation" {
  depends_on = [aws_acm_certificate_validation.cert_validation]

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

