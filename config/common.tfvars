project         = "EKS"

project_long    = "EKS-ELEVATOR"

primary_region = "eu-north-1"

region_secondary      = "us-east-2"

# Accounts
accounts = {
  root = {
    email = "",
    id    = 111111111111
  },
  security = {
    email = "",
    id    = 222222222222
  },
  shared = {
    email = "",
    id    = 333333333333
  },
  network = {
    email = "",
    id    = 444444444444
  },
  dev = {
    email = "",
    id    = 555555555555
  },
  prod = {
    email = "",
    id    = 666666666666
  }
  staging = {
    email = "",
    id    = 666666666666
  }
}

external_accounts = {
  drata = {
    aws_account_id  = ""
    aws_external_id = ""
  }
  scale = {
    aws_account_id  = ""
    aws_external_id = ""
  }
}

sso_enabled   = true
sso_region    = "eu-north-1"

enable_tgw = false

enable_tgw_multi_region = false

tgw_cidrs = ["172.0.0.0/8", "10.0.0.0/8"]