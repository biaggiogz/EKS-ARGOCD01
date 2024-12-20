
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.31.2"
  cluster_name          = var.cluster_name
  enable_v1_permissions = true
  namespace             = "karpenter"
  enable_irsa= true
  create_iam_role = true
  node_iam_role_use_name_prefix   = false
  enable_pod_identity             = true
  create_pod_identity_association = false
  enable_spot_termination = true
  node_iam_role_name = "role-node-karpenter-${var.cluster_name}"
  queue_name = "karpenter-${var.cluster_name}"
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  irsa_oidc_provider_arn = var.eks_oidc_provider_arn

  tags = {
    "enviroment" = var.environment_name
  }
}
resource "aws_iam_role_policy_attachment" "karpenter_loadbalancer_policy" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = "role-node-karpenter-${var.cluster_name}"
}

resource "aws_iam_role_policy_attachment" "karpenter_ec2_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = "role-node-karpenter-${var.cluster_name}"
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name           = var.cluster_name
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
              --cluster "${var.cluster_name}" \
              --arn "${module.karpenter.node_iam_role_arn}" \
              --group system:bootstrappers \
              --group system:nodes
    EOT
  }
}
resource "helm_release" "karpenter" {
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  repository_username =data.aws_ecrpublic_authorization_token.token.user_name
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
    clusterName: ${var.cluster_name}
    clusterEndpoint: ${var.cluster_endpoint}
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
resource "null_resource" "delete_mapping_karpenter" {
  triggers = {
    always_run = var.ignore_delete_mapping_karpenter ? "false" : "true"
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
            if [ "${var.ignore_delete_mapping_karpenter}" = "false" ]; then
              eksctl delete iamidentitymapping \
                --cluster "${var.cluster_name}" \
                --arn "${module.karpenter.node_iam_role_arn}";
            else
              echo "Ignore is set to true. Skipping execution.";
            fi
    EOT
  }
}
