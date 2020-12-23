terraform {
  backend "s3" {
    bucket         = "mediacodex-dev-terraform-state"
    key            = "core.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dev-terraform-lock"
    workspace_key_prefix = "state"
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
  region              = "us-east-1"
  allowed_account_ids = var.deploy_aws_accounts[local.environment]
  assume_role {
    role_arn = var.deploy_aws_roles[local.environment]
  }
}

provider "cloudflare" {}
