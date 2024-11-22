


module "eks_blueprints_addons" {

  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0"
  cluster_name      = local.cluster_name
  cluster_endpoint  = local.cluster_endpoint
  cluster_version   = local.cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_karpenter = true
  karpenter_enable_spot_termination = true

  karpenter = {
    chart_version       = "0.37.6"
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }

  karpenter_node =  {
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    coredns = {
      preserve = true
    }
    vpc-cni = {
      preserve = true
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          # ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          # AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = true
        }
      })
    }
    kube-proxy = {
      preserve = true
    }
  }

  enable_aws_efs_csi_driver = true


  enable_metrics_server = true
  metrics_server = {
    values = [templatefile("${path.module}/helm-values/metrics-server-values.yaml", {})]
  }

  #enable_aws_load_balancer_controller = true

  /*enable_metrics_server = true
  metrics_server = {
    values = [templatefile("${path.module}/helm-values/metrics-server-values.yaml", {})]
  }
*/

 /*
  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    values = [templatefile("${path.module}/helm-values/cluster-autoscaler-values.yaml", {
      aws_region     = local.region,
      eks_cluster_id = module.eks.cluster_name
    })]
  }
*/


  enable_aws_cloudwatch_metrics = true
  aws_cloudwatch_metrics = {
    values = [
      <<-EOT
        resources:
          limits:
            cpu: 500m
            memory: 1Gi
          requests:
            cpu: 200m
            memory: 800Mi

        # This toleration allows Daemonset pod to be scheduled on any node, regardless of their Taints.
        tolerations:
          - operator: Exists
      EOT
    ]
  }
  enable_kube_prometheus_stack = true
  kube_prometheus_stack = { ###REMEMBER UPDATE THIS CHART
    values = [
        local.enable_amazon_prometheus ? templatefile("${path.module}/helm-values/kube-prometheus-amp-enable.yaml", {
        region              = local.region
        amp_sa              = local.amp_ingest_service_account
        amp_irsa            = module.amp_ingest_irsa[0].iam_role_arn
        amp_remotewrite_url = "https://aps-workspaces.${local.region}.amazonaws.com/workspaces/${aws_prometheus_workspace.amp[0].id}/api/v1/remote_write"
        amp_url             = "https://aps-workspaces.${local.region}.amazonaws.com/workspaces/${aws_prometheus_workspace.amp[0].id}"
        storage_class_type  = kubernetes_storage_class.ebs_csi_encrypted_gp3_storage_class.id
      }) : templatefile("${path.module}/helm-values/kube-prometheus.yaml", {})
    ]
    chart_version = "66.2.0"
    set_sensitive = [
      {
        name  = "grafana.adminPassword"
        value = local.admin_password_version_grafana
      }
    ],
  }

  tags = local.labels

  depends_on = [module.ebs_csi_driver_irsa , kubernetes_storage_class.ebs_csi_encrypted_gp3_storage_class]
}





module "eks-data-addons" {
    source  = "aws-ia/eks-data-addons/aws"
    version = "1.35.0"
    oidc_provider_arn = local.eks_oidc_provider_arn

  enable_spark_operator = local.spark_team_namespace_created ? true : false
  spark_operator_helm_config = {
    values = [templatefile("${path.module}/helm-values/spark-operator-values.yaml", {})]
  }

  depends_on = [module.eks_blueprints_addons]
}



resource "aws_prometheus_workspace" "amp" {
  count = local.enable_amazon_prometheus ? 1 : 0

  alias = format("%s-%s", "amp-ws", local.name)
  tags  = local.tags
}

module "amp_ingest_irsa" {
  count = local.enable_amazon_prometheus ? 1 : 0
  source         = "aws-ia/eks-blueprints-addon/aws"
  version        = "1.1.1"
  create_release = false
  create_role    = true
  create_policy  = false
  role_name      = format("%s-%s", local.name, "amp-ingest")
  role_policies  = { amp_policy = local.policy_grafana_arn , prometheusquery = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess",
                    prometheuswrite = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"}

  oidc_providers = {
    this = {
      provider_arn    = local.eks_oidc_provider_arn
      namespace       = local.amp_namespace
      service_account = local.amp_ingest_service_account
    }
  }

  tags = local.tags
}


resource "helm_release" "kubecost" {
  name             = "kubecost"
  repository       = "oci://public.ecr.aws/kubecost"
  chart            = "cost-analyzer"
  version          = "2.4.2"
  namespace        = "kubecost"
  create_namespace = false

  values = [
    templatefile("${path.module}/helm-values/kubecost-values.yaml",{

      AMP_WORKSPACE_ID = aws_prometheus_workspace.amp[0].id
      AWS_REGION = local.region
      CLUSTER_NAME = local.cluster_name


    }),
    templatefile("${path.module}/helm-values/kubecost-images-values.yaml",{})
  ]

  depends_on = [module.eks_blueprints_addons]

}

resource "null_resource" "wait_for_spark_operator" {
  depends_on = [module.eks-data-addons]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --namespace spark-operator \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=spark-operator \
        --timeout=90s
    EOT
  }
}