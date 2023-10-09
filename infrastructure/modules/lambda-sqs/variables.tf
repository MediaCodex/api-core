variable "function_name" {
  type        = string
  description = "Name of target function"
}

variable "function_role_name" {
  type        = string
  description = "Name of target function's execution role"
}

variable "queue_arn" {
  type        = string
  description = "ARN of the aource SQS queue"
}

variable "batch_size" {
  type        = number
  description = "SQS Message batch size"
  default     = 1
}
