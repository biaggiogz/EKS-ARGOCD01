
data "aws_caller_identity" "current" {}


data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

locals {
  existing_map_roles = yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles)
  new_map_roles = [
    {
      rolearn = ""
      username = "system:node:{{EC2PrivateDNSName}}"
      groups =["system:bootstrappers","system:nodes"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8sDev"
      username = "dev-user"
      groups   = []
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8sInteg"
      username = "integ-user"
      groups   = []
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8sAdmin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  combined_map_roles = concat(local.existing_map_roles, local.new_map_roles)
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.combined_map_roles)
  }

  force = true
}