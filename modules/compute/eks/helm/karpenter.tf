
##first this

#helm registry logout public.ecr.aws
#docker logout public.ecr.aws

#second this
/*
      export KARPENTER_NAMESPACE="kube-system"
      export KARPENTER_VERSION="1.0.8"
      export K8S_VERSION="1.30"
      export AWS_PARTITION="aws"
      export CLUSTER_NAME="EKS-01"
      export AWS_DEFAULT_REGION="eu-north-1"
      export TEMPOUT="$(mktemp)"
 */


## third this
/*
curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/v"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

*/

###roles ready eks/iam.tf and modules/security/kubernetes/kubernetes-config-map.tf then


resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "karpenter"
  create_namespace = true
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.8"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = local.karpenter_role_arn
  }

  set {
    name  = "settings.clusterName"
    value = local.cluster_name
  }

  set {
    name  = "settings.interruptionQueue"
    value = local.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = local.cluster_endpoint
  }

  set {
    name  = "settings.featureGates.drift"
    value = "true"
  }

  set {
    name  = "settings.featureGates.SpotToSpotConsolidation"
    value = "true"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "500Mi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "500Mi"
  }
  set {
    name  = "logLevel"
    value = "debug"
  }

  wait =   true

}