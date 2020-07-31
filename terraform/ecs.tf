/*
 * ECS
 */
resource "aws_ecs_cluster" "api" {
  name = "api"

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
  name = "esc-api.mediacodex.local"
  vpc  = aws_vpc.ecs_api.id
}

resource "aws_service_discovery_service" "ecs_api" {
  name = "api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_api.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

/*
 * Outputs
 */
output "ecs_api_discovery" {
  value = aws_service_discovery_service.ecs_api.id
}

output "ecs_api_cluster" {
  value = aws_ecs_cluster.api.arn
}
