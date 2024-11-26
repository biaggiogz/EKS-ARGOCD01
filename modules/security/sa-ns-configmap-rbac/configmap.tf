


locals {
  existing_map_roles = yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles)
  karpenter_node_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${local.cluster_name}"

  new_map_roles = [
    {
      rolearn  = local.karpenter_node_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
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

  combined_map_roles = distinct(concat(local.existing_map_roles, local.new_map_roles))

  unique_map_roles = [
    for i, role in local.combined_map_roles :
    role if index(local.combined_map_roles, role) == i
  ]
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