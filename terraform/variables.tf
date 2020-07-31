locals {
  environment      = "${lookup(var.environments, terraform.workspace, "dev")}"
  domain           = lookup(var.domains, local.environment)
  firebase_project = lookup(var.firebase_projects, local.environment)
  api_cluster_name = "${local.environment}-api"
}

variable "environments" {
  type = map(string)
  default = {
    development = "dev"
    production  = "prod"
  }
}

variable "default_tags" {
  type        = map(string)
  description = "Common resource tags for all resources"
  default = {
    Service = "core"
  }
}

variable "terraform_state" {
  type = map(string)
  default = {
    bucket = "arn:aws:s3:::terraform-state-mediacodex"
    dynamo = "arn:aws:dynamodb:eu-central-1:939514526661:table/terraform-state-lock"
  }
}

variable "domains" {
  type = map
  default = {
    dev  = "mediacodex.dev"
    prod = "mediacodex.net"
  }
}

variable "first_deploy" {
  type        = bool
  description = "Disables some resources that depend on other services being deployed"
  default     = false
}

variable "ecs_capacity" {
  type        = map(number)
  description = "Target capacity for API spot fleet"
  default = {
    dev  = 2
    prod = 5
  }
}

variable "firebase_projects" {
  type = map(string)
  default = {
    "dev"  = "mediacodex-dev"
    "prod" = "mediacodex-prod"
  }
}

variable "cors_origins" {
  type = map(list(string))
  default = {
    dev  = ["*"]
    prod = ["https://mediacodex.net"]
  }
}

variable "cors_expose" {
  type = map(list(string))
  default = {
    dev  = ["*"]
    prod = []
  }
}
