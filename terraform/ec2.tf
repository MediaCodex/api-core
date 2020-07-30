/*
 * EC2
 */
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_launch_template" "ecs_api" {
  name_prefix   = "ecs-api"
  image_id      = data.aws_ami.amazon_linux_ecs.id
  instance_type = "t3a.micro"

  instance_market_options {
    market_type = "spot"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = var.default_tags
}

resource "aws_autoscaling_group" "ecs_api" {
  vpc_zone_identifier   = [for subnet in aws_subnet.ecs_api : subnet.id]
  protect_from_scale_in = true

  // capacity
  desired_capacity = local.environment == "prod" ? 2 : 1
  max_size         = local.environment == "prod" ? 6 : 2
  min_size         = local.environment == "prod" ? 2 : 1

  launch_template {
    id      = aws_launch_template.ecs_api.id
    version = "$Latest"
  }

  // auto-added by ECS, causing a difference to be detected
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

/*
 * VPC
 */
resource "aws_vpc" "ecs_api" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.default_tags, {
    Name = "API (ECS)"
  })
}

resource "aws_subnet" "ecs_api" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.ecs_api.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = var.default_tags
}
