resource "aws_ssm_parameter" "dns_zone" {
  name  = "/core/cloudflare-zone"
  type  = "String"
  value = cloudflare_zone.main.id
}

# ----------------------------------------------------------------------------------------------------------------------
# CDN
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "cdn_avatars_bucket" {
  name  = "${local.cdn_buckets_ssm_prefix}avatars"
  type  = "String"
  value = aws_s3_bucket.avatars.id
}

# ----------------------------------------------------------------------------------------------------------------------
# Gateway
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "gateway_public_domain" {
  name  = "/core/gateway-domain"
  type  = "String"
  value = aws_apigatewayv2_domain_name.main.id
}

resource "aws_ssm_parameter" "cognito_pool_id" {
  name  = "/core/cognito-pool-id"
  type  = "String"
  value = aws_cognito_user_pool.main.id
}

resource "aws_ssm_parameter" "cognito_password_policy" {
  name  = "/core/cognito-password-policy"
  type  = "String"
  value = jsonencode(aws_cognito_user_pool.main.password_policy[0])
}

resource "aws_ssm_parameter" "cognito_client_website" {
  name  = "/core/cognito-client-website"
  type  = "StringList"
  value = join(",", [aws_cognito_user_pool_client.website.id])
}
