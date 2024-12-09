resource "helm_release" "aws_cloud_watch" {

  name             = "aws-cloudwatch-metrics"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-cloudwatch-metrics"
  namespace        = "kube-system"
  create_namespace = false
  version          = "0.0.11"

  values = [templatefile("${path.module}/values/cloudwatch.yaml", {
    clustername = local.cluster_name

  })]

}