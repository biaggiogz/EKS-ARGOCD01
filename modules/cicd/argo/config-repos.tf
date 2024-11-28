/*resource "argocd_repository" "privateEKS-ArgoCD" {
  repo     = local.github_repo_url
  name     = "EKS-ARGOCD01"
  insecure = false
  ssh_private_key =file("/home/aniking/.ssh/githueks_terraform")
}
*/