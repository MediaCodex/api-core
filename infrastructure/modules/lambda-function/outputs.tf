output "role_id" {
  value       = aws_iam_role.lambda_execution.id
  description = "Name of lambda execution role"
}

output "role_arn" {
  value       = aws_iam_role.lambda_execution.arn
  description = "ARN of the lambda execution role"
}

output "function_arn" {
  value       = aws_lambda_function.default.arn
  description = "ARN of Lambda function"
}

output "function_invoke_arn" {
  value       = aws_lambda_function.default.invoke_arn
  description = "ARN for invoking the Lambda function"
}

output "function_name" {
  value       = aws_lambda_function.default.function_name
  description = "Name of Lambda function"
}

output "dlq_arn" {
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
  description = "ARN of the SQS queue for failed invocations"
}
