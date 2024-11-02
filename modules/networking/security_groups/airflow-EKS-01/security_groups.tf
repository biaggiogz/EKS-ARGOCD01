resource "aws_security_group" "efs_airflow" {
  name        = "Airflow-on-EKS-01"
  description = "Airflow-on-EKS-01"
  vpc_id      =  data.terraform_remote_state.vpc.outputs.vpc_id


tags = {
    Name = "Airflow-on-EKS-01"
  }
}

resource "aws_security_group_rule" "efs_ingress_aiflow" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.efs_airflow.id

  depends_on = [aws_security_group.efs_airflow]
}