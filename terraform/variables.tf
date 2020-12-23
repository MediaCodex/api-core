locals {
  environment      = contains(var.environments, terraform.workspace) ? terraform.workspace : "dev"
  domain           = lookup(var.domains, local.environment)
  firebase_project = lookup(var.firebase_projects, local.environment)
  api_cluster_name = "${local.environment}-api"
}

/**
 * Terraform
 */
variable "environments" {
  type = set(string)
  default = ["dev", "prod"]
}

variable "terraform_state" {
  type = map(string)
  default = {
    bucket = "arn:aws:s3:::terraform-state-mediacodex"
    dynamo = "arn:aws:dynamodb:eu-central-1:939514526661:table/terraform-state-lock"
  }
}

/**
 * AWS
 */
variable "default_tags" {
  type        = map(string)
  description = "Common resource tags for all resources"
  default = {
    Service = "core"
  }
}

variable "domains" {
  type = map
  default = {
    dev  = "mediacodex.dev"
    prod = "mediacodex.net"
  }
}

/**
 * ECS
 */
variable "ecs_capacity" {
  type        = map(number)
  description = "Target capacity for API spot fleet"
  default = {
    dev  = 1
    prod = 3
  }
}

variable "ecs_zones" {
  type = list(string)
  description = "AZs to run ECS cluster in"
  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
    "us-east-1d"
  ]
}

/**
 * Firebase
 */
variable "firebase_projects" {
  type = map(string)
  default = {
    "dev"  = "mediacodex-dev"
    "prod" = "mediacodex-prod"
  }
}

/**
 * Toggles
 */
variable "first_deploy" {
  type        = bool
  description = "Disables some resources that depend on other services being deployed"
  default     = false
}
