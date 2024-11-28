locals {

 # argocd_url =  data.external.url_argocd.result.url_argocd
  #admin_token =  data.terraform_remote_state.secrets.outputs.admin_token
  context_prefix = "terraform-workshop"
  github_repo_url = "git@github.com:biaggiogz/EKS-ARGOCD01.git"
  ssh_key_basepath = "/home/aniking/.ssh"
  ssh_host = "github.com"
  region = data.terraform_remote_state.global-variables.outputs.region
  #karpenter_role_arn =data.terraform_remote_state.eks.outputs.karpenter_role_arn
  cluster_name =data.terraform_remote_state.eks.outputs.cluster_name
  cluster_endpoint= data.terraform_remote_state.eks.outputs.cluster_endpoint
  #karpenter_node_instance_profile_name = data.terraform_remote_state.eks_addons.outputs.karpenter_node_instance_profile_name
 # karpenter_sqs_name =data.terraform_remote_state.eks_addons.outputs.karpenter_sqs_name
  common_tags = {
    environment                    = data.terraform_remote_state.global-variables.outputs.environment_name
    "app.kubernetes.io/managed-by"  = "Terraform"
    "app.kubernetes.io/part-of"   = data.terraform_remote_state.global-variables.outputs.environment_name
    "cluster_name" = data.terraform_remote_state.eks.outputs.cluster_name
  }

}