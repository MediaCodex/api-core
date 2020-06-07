resource "aws_api_gateway_rest_api" "default" {
  name = "mediacodex"
  tags = var.default_tags
}

output "gateway_id" {
  value       = aws_api_gateway_rest_api.default.id
  description = "ID for primary API Gateway"
}

output "gateway_root" {
  value       = aws_api_gateway_rest_api.default.root_resource_id
  description = "Root resource of primary API Gateway"
}