module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Complete PostgreSQL example security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = "${local.vpc_cidr_block},${local.vpc_secondary_cidr_blocks[0]}"
    },
  ]

  tags = {
    Blueprint  = local.name
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.0"

  identifier = local.airflow_name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  instance_class    = "db.t4g.large"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "16.3"
  family            = "postgres16"
  major_engine_version = "16"

  max_allocated_storage = 100

  db_name                = local.airflow_name
  username               = local.airflow_name
  create_random_password = false
  password               = sensitive(local.password)
  port                   = 5432

  multi_az               = true
  db_subnet_group_name   = data.terraform_remote_state.vpc.outputs.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "airflow-metastore"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Airflow Postgres Metastore for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  depends_on = [module.security_group]

}



/*

resource "aws_db_instance" "airflow-postgres-EKS-01" {
  identifier        = "airflow-postgres"
  instance_class    = "db.t4g.large"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "16.3"  # Specify the desired Postgres version
  db_name           = "airflow"
  username          = "airflowadmin"
  password          = "admin2024.*"  # Consider using a secret manager for passwords

  db_subnet_group_name   = aws_db_subnet_group.airflow_postgres_subnet-EKS-01.name
  vpc_security_group_ids = [aws_security_group.airflow-rds_sg-EKS-01.id]  # You'll need to create this security group

  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "Airflow Postgres RDS Instance EKS-01"
  }

  depends_on = [aws_security_group.airflow-rds_sg-EKS-01]
}




*/


/*

data "tls_certificate" "eks" {
  url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}
/*
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}

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

resource "aws_db_subnet_group" "airflow_postgres_subnet-EKS-01" {
  name        = "airflow-postgres-subnet-eks-01"
  description = "Subnet group for Postgres RDS"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  tags = {
    Name = "Airflow Postgres Subnet Group EKS-01"
  }
  depends_on = [aws_efs_access_point.airflow-EKS-01]
}


resource "aws_security_group" "airflow-rds_sg-EKS-01" {
  name        = "airflow-postgres-sg"
  description = "Security group for Airflow Postgres RDS EKS-01"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Airflow Postgres RDS Security Group EKS-01"
  }
}

resource "aws_db_instance" "airflow-postgres-EKS-01" {
  identifier        = "airflow-postgres"
  instance_class    = "db.t4g.large"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "16.3"  # Specify the desired Postgres version
  db_name           = "airflow"
  username          = "airflowadmin"
  password          = "admin2024.*"  # Consider using a secret manager for passwords

  db_subnet_group_name   = aws_db_subnet_group.airflow_postgres_subnet-EKS-01.name
  vpc_security_group_ids = [aws_security_group.airflow-rds_sg-EKS-01.id]  # You'll need to create this security group

  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "Airflow Postgres RDS Instance EKS-01"
  }

  depends_on = [aws_security_group.airflow-rds_sg-EKS-01]
}

resource "null_resource" "wait_5_minutes" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for 5 minutes..."
      sleep 300
      echo "5 minutes have passed."
    EOT
  }

  depends_on = [aws_db_instance.airflow-postgres-EKS-01]
}
*/