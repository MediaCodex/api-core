locals {
  cognito_domain   = "auth.${cloudflare_zone.main.zone}"
}

# ----------------------------------------------------------------------------------------------------------------------
# User Pool
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_user_pool" "main" {
  name = "MediaCodex"

  mfa_configuration = "OPTIONAL"

  username_attributes = [
    "email"
  ]

  auto_verified_attributes = [
    "email"
  ]

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = local.email_from_friendly
    source_arn            = aws_sesv2_email_identity.noreply.arn
  }

  lambda_config {
    post_authentication  = module.functions.cognito_function_arns.post_authentication
    # TODO: setup MJML email templates
    # custom_message       = module.functions.cognito_function_arns.custom_message
  }
}

resource "aws_cognito_user_pool_client" "dashboard" {
  name            = "dashboard"
  user_pool_id    = aws_cognito_user_pool.main.id
  generate_secret = false

  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows          = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "profile"]

  callback_urls = concat(var.auth_callback_urls, [
    "https://${cloudflare_zone.main.zone}"
  ])
}

# ----------------------------------------------------------------------------------------------------------------------
# SSM Params
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "cognito_pool_id" {
  name  = "/gateway-public/cognito/pool-id"
  type  = "String"
  value = aws_cognito_user_pool.main.id
}

resource "aws_ssm_parameter" "cognito_password_polic" {
  name  = "/gateway-public/cognito/password-policy"
  type  = "String"
  value = jsonencode(aws_cognito_user_pool.main.password_policy[0])
}

resource "aws_ssm_parameter" "cognito_client_dashboard" {
  name  = "/gateway-public/cognito/client-dashboard"
  type  = "String"
  value = aws_cognito_user_pool_client.dashboard.id
}
