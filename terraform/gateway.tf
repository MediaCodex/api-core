resource "aws_apigatewayv2_api" "default" {
  name = "mediacodex"
  protocol_type = "HTTP"
  tags = var.default_tags
}

output "gateway_id" {
  value       = aws_apigatewayv2_api.default.id
  description = "ID for primary API Gateway"
}

output "gateway_execution" {
  value       = aws_apigatewayv2_api.default.execution_arn
  description = "Invoke ARN of primary API Gateway"
}