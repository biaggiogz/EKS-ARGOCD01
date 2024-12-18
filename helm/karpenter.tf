data "aws_caller_identity" "current" {}

module "common_vars" {
  source = "../common-files"
}
module "eks_outputs" {
  source = "../outputs_terraform_tfstate"
}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}
locals {
  cluster_endpoint = module.eks_outputs.cluster_endpoint
  cluster_version = module.eks_outputs.cluster_version
  eks_oidc_provider_arn = module.eks_outputs.eks_oidc_provider_arn
  cluster_oidc_issuer_url = module.eks_outputs.cluster_oidc_issuer_url
  cluster_name = module.common_vars.cluster_name
  cluster_certificate_authority_data = module.eks_outputs.cluster_certificate_authority_data
  region = "eu-north-1"
  KARPENTER_VERSION="1.0.8"
}
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"
  cluster_name          = local.cluster_name
  enable_v1_permissions = true
  namespace             = "karpenter"
  enable_irsa= true
  create_iam_role = true
  node_iam_role_use_name_prefix   = false
  enable_pod_identity             = true
  create_pod_identity_association = false
  enable_spot_termination = true
  node_iam_role_name = "role-node-karpenter-${local.cluster_name}"
  queue_name = "karpenter-${local.cluster_name}"
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  irsa_oidc_provider_arn = local.eks_oidc_provider_arn

  tags = {
    "enviroment" = module.common_vars.environment_name
  }
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name           = local.cluster_name
  namespace              = "karpenter"
  service_account        = "karpenter"
  role_arn               = module.karpenter.iam_role_arn
}

resource "null_resource" "mapping_karpenter" {
  triggers = {
    always_run = module.karpenter.node_iam_role_arn
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
            eksctl create iamidentitymapping \
              --username system:node:{{EC2PrivateDNSName}} \
              --cluster "${local.cluster_name}" \
              --arn "${module.karpenter.node_iam_role_arn}" \
              --group system:bootstrappers \
              --group system:nodes
    EOT
  }
}
resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = "karpenter"
  create_namespace    =  false
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = "1.0.8"
  wait                = true
  values = [
    <<-EOT
  settings:
    serviceAccount:
      name: karpenter
      annotations:
        eks.amazonaws.com/role-arn: "${module.karpenter.iam_role_arn}"
    clusterName: ${local.cluster_name}
    clusterEndpoint: ${local.cluster_endpoint}
    interruptionQueue: ${module.karpenter.queue_name}
    featureGates:
      spotToSpotConsolidation: true
  controller:
    env:
      - name: KARPENTER_RESPECT_YUNIKORN_SCHEDULING
        value: "true"
    resources:
      requests:
        cpu: 500m
        memory: 500Mi
      limits:
        cpu: "1"
        memory: 1G
  webhook:
    # -- Whether to enable the webhooks and webhook permissions.
    enabled: true
    # -- The container port to use for the webhook.
    port: 8443
    metrics:
      # -- The container port to use for webhook metrics.
      port: 8001
  EOT
  ]



  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
/*


resource "null_resource" "pod_identity" {
  triggers = {
    always_run = module.karpenter.node_iam_role_arn
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
              aws eks describe-pod-identity-association \
                --cluster-name ${local.cluster_name} \
                --association-id ${aws_eks_pod_identity_association.karpenter.id}
    EOT
  }
}

*/
