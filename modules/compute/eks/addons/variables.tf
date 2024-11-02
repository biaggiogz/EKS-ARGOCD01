variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "EKS-01"
}

variable "namespace_csi_driver" {
  default = "kube-system"
}

