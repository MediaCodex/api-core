/*
 * ECS
 */
resource "aws_ecs_cluster" "api" {
  name = "api"
  capacity_providers = [aws_ecs_capacity_provider.api.name]
  tags = var.default_tags
}

resource "aws_ecs_capacity_provider" "api" {
  name = aws_autoscaling_group.ecs_api.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_api.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
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
 * Registry
 */
resource "aws_ecr_repository" "ecs_api" {
  name                 = "api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = var.default_tags
}

# resource "aws_ecr_repository_policy" "ecs_api" {
#   repository = aws_ecr_repository.ecs_api.name
#   policy = data.aws_iam_policy_document.ecs_api_repository.json
# }

# data "aws_iam_policy_document" "ecs_api_repository" {
#   statement {
#     principals {
#       type = "AWS"
#       identifiers = [aws_ecs_cluster.api.arn]
#     }
#     actions = [
#       "ecr:GetDownloadUrlForLayer",
#       "ecr:BatchGetImage",
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:DescribeRepositories",
#       "ecr:GetRepositoryPolicy",
#       "ecr:ListImages"
#     ]
#   }
# }

/*
 * Outputs
 */
output "ecs_api_discovery" {
  value = aws_service_discovery_service.ecs_api.id
}

output "ecs_api_cluster" {
  value = aws_ecs_cluster.api.arn
}

output "ecs_api_repository" {
  value = aws_ecr_repository.ecs_api.name
}
