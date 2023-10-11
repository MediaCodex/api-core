locals {
  build_dir = "${path.module}/../../dist"

  envvar_tables = {
    "DYNAMODB_TABLE_USERS" = var.ddb_table_names.users
  }

  envvar_default = merge(local.envvar_tables, var.environment)
}

# ----------------------------------------------------------------------------------------------------------------------
# Misc
# ----------------------------------------------------------------------------------------------------------------------
variable "prefix" {
  type    = string
  default = ""
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "email_allowed_from_addresses" {
  type = list(string)
}

variable "user_sync_queue_arn" {
  type = string
}

variable "user_sync_queue_url" {
  type = string
}

variable "avatars_bucket" {
  type = string
}

variable "cdn_buckets_map" {
  type        = map(string)
  description = "cdn_dir => bucket_arn"
}

variable "cdn_event_bus" {
  type = string
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS
# ----------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type = string
}

variable "aws_account" {
  type = string
}

variable "cognito_pool_id" {
  type = string
}

variable "cognito_pool_arn" {
  type = string
}

variable "ddb_table_arns" {
  type = object({
    users = string
  })
}

variable "ddb_table_names" {
  type = object({
    users = string
  })
}
