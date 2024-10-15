project         = "EKS"

project_long    = "EKS-ELEVATOR"

region_primary = "eu-north-1"

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
  apps-devstg = {
    email = "",
    id    = 555555555555
  },
  apps-prd = {
    email = "",
    id    = 666666666666
  }
  data-science = {
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
sso_start_url = "https://leverage.awsapps.com/start"
sso_region    = "us-east-1"

enable_tgw = false

enable_tgw_multi_region = false

tgw_cidrs = ["172.0.0.0/8", "10.0.0.0/8"]