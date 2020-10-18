terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "MediaCodex"

    workspaces {
      prefix = "service-core-"
    }
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
  version             = "~> 3.0"
  region              = "eu-central-1"
  allowed_account_ids = var.deploy_aws_accounts[local.environment]
  assume_role {
    role_arn = var.deploy_aws_roles[local.environment]
  }
}

provider "aws" {
  alias               = "eu_west_1"
  version             = "~> 3.0"
  region              = "eu-west-1"
  allowed_account_ids = var.deploy_aws_accounts[local.environment]
  assume_role {
    role_arn = var.deploy_aws_roles[local.environment]
  }
}

provider "aws" {
  alias               = "us_east_1"
  version             = "~> 3.0"
  region              = "us-east-1"
  allowed_account_ids = var.deploy_aws_accounts[local.environment]
  assume_role {
    role_arn = var.deploy_aws_roles[local.environment]
  }
}

provider "cloudflare" {
  version = "~> 2.0"
}

data "terraform_remote_state" "website" {
  backend   = "s3"
  workspace = terraform.workspace
  config = {
    bucket       = "terraform-state-mediacodex"
    key          = "website.tfstate"
    region       = "eu-central-1"
    role_arn     = "arn:aws:iam::939514526661:role/remotestate/core"
    session_name = "terraform"
  }
}
