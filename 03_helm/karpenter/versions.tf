
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

provider "aws" {
  region = "eu-north-1"

}

provider "aws" {
  alias  = "ecr"
  region = "us-east-1"
}
