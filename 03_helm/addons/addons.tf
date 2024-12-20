data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {

  region = "eu-north-1"
  tags = {
    "enviroment" = var.environment_name
  }

}

module "eks_blueprints_kubernetes_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.18.0"
  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.eks_oidc_provider_arn

  enable_metrics_server = true
  enable_aws_load_balancer_controller = true
  enable_cert_manager                 = true
  enable_aws_efs_csi_driver = true
  enable_aws_fsx_csi_driver = true
  metrics_server ={
    chart_version ="3.12.0"
    values = [ templatefile("${path.module}/metric-server.yaml",{} )
    ]
  }
  cert_manager = {
    chart_version = "v1.16.0"
    values = [
      <<-EOT
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: helm.team.dev/helm
                      operator: Exists
    EOT
    ]
  }

  aws_efs_csi_driver = {
    namespace     = "kube-system"
    chart_version = "3.0.6"
    values = [
      <<-EOT
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: eks.amazonaws.com/compute-type
                      operator: NotIn
                      values:
                        - fargate
                        - hybrid
                    - key: helm.team.dev/helm
                      operator: Exists
      EOT
    ]
  }

  aws_load_balancer_controller = {
    chart_version = "1.8.4"
  }

  aws_fsx_csi_driver = {
    namespace     = "kube-system"
#    chart_version = "1.9.0"
    values = [
      <<-EOT
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: helm.team.dev/helm
                      operator: Exists
    EOT
    ]
  }


  tags = local.tags
}
