variable "name" {
  type        = string
  description = "Name of the IAM policy"
  default     = "DynamoDB"
}

variable "role" {
  type        = string
  description = "ARN of IAM role to attach the policy to"
}

variable "tables" {
  type = list(object({
    arn           = string
    enable_read   = optional(bool, false)
    enable_write  = optional(bool, false)
    enable_delete = optional(bool, false)
    enable_stream = optional(bool, false)
  }))
}
