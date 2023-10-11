# ----------------------------------------------------------------------------------------------------------------------
# Auth Gateway
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "auth" {
  name          = "${local.prefix}auth"
  protocol_type = "HTTP"

  disable_execute_api_endpoint = true

  cors_configuration {
    allow_headers  = ["*"]
    allow_methods  = ["*"]
    allow_origins  = lookup(var.cors_origins, local.environment)
    expose_headers = lookup(var.cors_expose, local.environment)
  }
}

resource "aws_apigatewayv2_stage" "auth_v1" {
  api_id      = aws_apigatewayv2_api.auth.id
  name        = "v1"
  auto_deploy = true

  // required due to bug https://github.com/hashicorp/terraform-provider-aws/issues/14742#issuecomment-750693332
  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  lifecycle {
    // auto-deploy changes this
    ignore_changes = [deployment_id]
  }

  route_settings {
    route_key              = aws_apigatewayv2_route.auth_user_sync.route_key
    throttling_rate_limit  = 1
    throttling_burst_limit = 5
  }
}

resource "aws_apigatewayv2_api_mapping" "api" {
  domain_name     = aws_apigatewayv2_domain_name.main.id
  api_id          = aws_apigatewayv2_api.auth.id
  stage           = aws_apigatewayv2_stage.auth_v1.id
  api_mapping_key = "${aws_apigatewayv2_stage.auth_v1.name}/auth"
}

resource "aws_apigatewayv2_authorizer" "auth_cognito" {
  api_id          = aws_apigatewayv2_api.auth.id
  authorizer_type = "JWT"
  name            = "cognito"

  identity_sources = [
    "$request.header.Authorization"
  ]

  jwt_configuration {
    issuer   = "https://${aws_cognito_user_pool.main.endpoint}"
    audience = [aws_cognito_user_pool_client.website.id]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# AuthSync Integration
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "auth_user_sync" {
  api_id             = aws_apigatewayv2_api.auth.id
  route_key          = "GET /sync"
  target             = "integrations/${aws_apigatewayv2_integration.auth_user_sync.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.auth_cognito.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_integration" "auth_user_sync" {
  api_id              = aws_apigatewayv2_api.auth.id
  credentials_arn     = aws_iam_role.auth_user_sync.arn
  description         = "SQS UserSync"
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"

  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.user_sync.url
    "MessageBody" = "$context.authorizer.claims.sub"
  }
}

resource "aws_iam_role" "auth_user_sync" {
  name               = "${local.prefix}gateway-auth-user-sync"
  assume_role_policy = data.aws_iam_policy_document.auth_user_sync_assume.json
}

data "aws_iam_policy_document" "auth_user_sync_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "auth_user_sync" {
  name   = "DynamoDB"
  role   = aws_iam_role.auth_user_sync.id
  policy = data.aws_iam_policy_document.auth_user_sync.json
}

data "aws_iam_policy_document" "auth_user_sync" {
  statement {
    sid       = "SQS"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.user_sync.arn]
  }
}
