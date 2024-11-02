
data "tls_certificate" "eks" {
  url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}
/*
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}
*/
resource "aws_efs_file_system" "airflow-EKS-01" {
  creation_token = "Airflow-on-EKS-01"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true


  tags = {
    Name = "AirflowVolume-EKS-01"
  }
}

resource "aws_efs_mount_target" "airflow-EKS-01" {
  count           = length(data.aws_eks_node_group.on_spot.subnet_ids)
  file_system_id  = aws_efs_file_system.airflow-EKS-01.id
  subnet_id       = element(tolist(data.aws_eks_node_group.on_spot.subnet_ids), count.index)
  security_groups = [data.terraform_remote_state.networking-SG-airflow-EKS-01.outputs.SG_id_efs_airflow]

  depends_on = [aws_efs_file_system.airflow-EKS-01]
}

resource "aws_efs_access_point" "airflow-EKS-01" {
  file_system_id = aws_efs_file_system.airflow-EKS-01.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/airflow"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }
  depends_on = [aws_efs_file_system.airflow-EKS-01]
}