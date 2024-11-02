

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_partition" "current" {}
/*data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}*/

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}