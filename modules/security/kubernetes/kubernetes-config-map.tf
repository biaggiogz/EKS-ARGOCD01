
data "aws_caller_identity" "current" {}


resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      concat(
        [
          {
            #rolearn  = module.eks.node_role_arn
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = ["system:bootstrappers", "system:nodes"]
          },
        ],
        [
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
      )
    )
  }
}

