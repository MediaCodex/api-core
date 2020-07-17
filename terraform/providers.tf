terraform {
  backend "s3" {
    bucket         = "terraform-state-mediacodex"
    key            = "core.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    role_arn       = "arn:aws:iam::939514526661:role/remotestate/core"
    session_name   = "terraform"
  }
}

variable "deploy_aws_roles" {
  type = map(string)
  default = {
    dev  = "arn:aws:iam::949257948165:role/deploy-core"
    prod = "arn:aws:iam::000000000000:role/deploy-core"
  }
}

variable "deploy_aws_accounts" {
  type = map(list(string))
  default = {
    dev  = ["949257948165"]
    prod = ["000000000000"]
  }
}

provider "aws" {
  version             = "~> 2.0"
  region              = "eu-central-1"
  allowed_account_ids = var.deploy_aws_accounts[local.environment]
  assume_role {
    role_arn = var.deploy_aws_roles[local.environment]
  }
}

provider "aws" {
  alias = "eu_west_1"
  version             = "~> 2.0"
  region              = "eu-west-1"
  allowed_account_ids = var.deploy_aws_accounts[local.environment]
  assume_role {
    role_arn = var.deploy_aws_roles[local.environment]
  }
}

provider "cloudflare" {
  version = "~> 2.0"
}
