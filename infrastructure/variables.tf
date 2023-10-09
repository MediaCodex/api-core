locals {
  environment = contains(var.environments, terraform.workspace) ? terraform.workspace : "dev"
  domain      = lookup(var.domains, local.environment)
  aws_account = lookup(var.aws_accounts, local.environment)
  prefix      = "core-"
}

variable "environments" {
  type    = set(string)
  default = ["dev", "prod"]
}

variable "domains" {
  type = map(any)
  default = {
    dev  = "mediacodex.dev"
    prod = "mediacodex.net"
  }
}

variable "email_spf_includes" {
  type    = list(string)
  default = ["_spf.google.com"]
}

# ----------------------------------------------------------------------------------------------------------------------
# API
# ----------------------------------------------------------------------------------------------------------------------
variable "cors_origins" {
  type = map(list(string))
  default = {
    dev  = ["*"]
    prod = ["https://littleurl.io"]
  }
}

variable "cors_expose" {
  type = map(list(string))
  default = {
    dev  = ["*"]
    prod = []
  }
}

variable "auth_callback_urls" {
  type        = list(string)
  description = "Additional callback domains for cognito client"
  default     = []
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS
# ----------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "default_tags" {
  type        = map(string)
  description = "Common resource tags for all resources"
  default = {
    Service = "core"
  }
}

variable "aws_accounts" {
  type = map(string)
  default = {
    dev  = "000000000000"
    prod = "000000000000"
  }
}

variable "aws_role" {
  type    = string
  default = "deploy-api"
}

# ----------------------------------------------------------------------------------------------------------------------
# Cloudflare
# ----------------------------------------------------------------------------------------------------------------------
variable "cloudflare_account_id" {
  type = string
}
