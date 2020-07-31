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

resource "aws_service_discovery_service" "ecs_api" {
  name = local.api_cluster_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_api.id

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
  value = aws_service_discovery_service.ecs_api.arn
}

output "ecs_api_cluster" {
  value = aws_ecs_cluster.api.arn
}
