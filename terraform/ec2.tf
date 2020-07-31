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

resource "aws_launch_template" "ecs_api" {
  name_prefix   = "ecs-api"
  instance_type = "t3a.micro"
  image_id      = data.aws_ami.amazon_linux_ecs.id

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs.arn
  }

  # ebs {
  #   delete_on_termination = true
  #   volume_type = "gp2"
  #   volume_size = 30
  # }

  monitoring {
    enabled = true
  }

  instance_market_options {
    market_type = "spot"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = var.default_tags
}

resource "aws_iam_instance_profile" "ecs" {
  name = "ecs"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_iam_role" "ecs_instance" {
  name               = "ecs-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

/*
 * Spot fleet
 */
resource "aws_spot_fleet_request" "ecs_api" {
  spot_price          = "0.03"
  fleet_type          = "maintain"
  allocation_strategy = "lowestPrice"
  iam_fleet_role      = aws_iam_role.ecs_spot_fleet.arn
  target_capacity     = lookup(var.ecs_capacity, local.environment)


  launch_template_config {
    launch_template_specification {
      id      = aws_launch_template.ecs_api.id
      version = aws_launch_template.ecs_api.latest_version
    }

    dynamic "overrides" {
      for_each = aws_subnet.ecs_api
      content {
        subnet_id = overrides.value.id
      }
    }
  }

  tags = var.default_tags
}

resource "aws_iam_role" "ecs_spot_fleet" {
  name               = "ecs-spot-fleet"
  assume_role_policy = data.aws_iam_policy_document.assume_spot_fleet.json
}

resource "aws_iam_role_policy_attachment" "ecs_spot_fleet" {
  role       = aws_iam_role.ecs_spot_fleet.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

data "aws_iam_policy_document" "assume_spot_fleet" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
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

data "aws_availability_zones" "available" {
  state = "available"
}