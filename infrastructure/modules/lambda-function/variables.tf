# ----------------------------------------------------------------------------------------------------------------------
# Common Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type = string
}

variable "aws_account" {
  type = string
}

# ----------------------------------------------------------------------------------------------------------------------
# Function
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type = string
}

variable "filename" {
  type = string
}

variable "handler" {
  type    = string
  default = "index.default"
}

variable "role_path" {
  type    = string
  default = "/lambda/"
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

# ----------------------------------------------------------------------------------------------------------------------
# Runtime
# ----------------------------------------------------------------------------------------------------------------------
variable "runtime" {
  type    = string
  default = "nodejs18.x"
}

variable "architectures" {
  type    = set(string)
  default = ["arm64"]
}

variable "timeout" {
  type    = number
  default = 5
}

variable "memory" {
  type    = number
  default = 128
}
