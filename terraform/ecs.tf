/*
 * ECS
 */
resource "aws_ecs_cluster" "api" {
  name = local.api_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.default_tags
}

/*
 * Service Map
 */
resource "aws_service_discovery_private_dns_namespace" "ecs_api" {
  name = "${local.api_cluster_name}.mediacodex.local"
  vpc  = aws_vpc.ecs_api.id
}

resource "aws_apigatewayv2_vpc_link" "ecs_api" {
  name               = local.api_cluster_name
  security_group_ids = [aws_security_group.ecs_api.id]
  subnet_ids         = [for subnet in aws_subnet.ecs_api: subnet.id]
  tags = var.default_tags
}

/*
 * Outputs
 */
output "ecs_api_namespace" {
  value = aws_service_discovery_private_dns_namespace.ecs_api.id
}

output "ecs_api_cluster" {
  value = aws_ecs_cluster.api.arn
}

output "ecs_api_gateway_link" {
  value = aws_apigatewayv2_vpc_link.ecs_api.id
}
