data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

provider "aws" {
  region = "eu-north-1"

}

provider "aws" {
  alias  = "ecr"
  region = "us-east-1"
}

locals {
  tags = {
    "enviroment" = var.environment_name
  }

}


module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name = substr("${var.region}-${var.cluster_name}-kube-cost", 0, 64) # Can only be 64 characters or less

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["kubecost:kubecost-cost-analyzer"]
    }
  }

}

resource "kubernetes_namespace" "kubecost" {

  metadata {
    labels = local.tags
    name = "kubecost"
  }
}

resource "helm_release" "kubecost" {
  name             = "kubecost"
  repository       = "oci://public.ecr.aws/kubecost"
  chart            = "cost-analyzer"
  version          = "2.4.2"
  namespace        = "kubecost"
  create_namespace = false
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  repository_username =data.aws_ecrpublic_authorization_token.token.user_name

  values = [
    templatefile("${path.module}/kubecost.yaml",{

      AWS_REGION = var.region
      CLUSTER_NAME = var.cluster_name


    })
  ]
    depends_on = [kubernetes_namespace.kubecost]

}