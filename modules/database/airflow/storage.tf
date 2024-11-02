
data "tls_certificate" "eks" {
  url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}