# ----------------------------------------------------------------------------------------------------------------------
# Function
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "default" {
  function_name = var.name
  role          = aws_iam_role.lambda_execution.arn

  # handler
  handler          = var.handler
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  # runtime
  runtime       = var.runtime
  architectures = var.architectures
  timeout       = var.timeout
  memory_size   = var.memory

  environment {
    variables = var.environment_variables
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Permssion
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_execution" {
  name               = var.name
  path               = var.role_path
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
