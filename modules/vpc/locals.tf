

locals {
  num_of_subnets  = min(length(data.aws_availability_zones.available.names), 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = {
    branch  = "dev-01"
  }

}