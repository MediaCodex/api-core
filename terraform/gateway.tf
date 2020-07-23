/*
 * Gateway
 */
resource "aws_apigatewayv2_api" "default" {
  name          = "mediacodex"
  protocol_type = "HTTP"
  tags          = var.default_tags
}

resource "aws_apigatewayv2_stage" "v1" {
  api_id      = aws_apigatewayv2_api.default.id
  name        = "v1"
  auto_deploy = true

  lifecycle {
    // auto-deploy changes this
    ignore_changes = [deployment_id]
  }

  tags = var.default_tags
}

resource "aws_apigatewayv2_authorizer" "firebase" {
  api_id           = aws_apigatewayv2_api.default.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "firebase"

  jwt_configuration {
    issuer   = "https://securetoken.google.com/${local.firebase_project}"
    audience = [local.firebase_project]
  }
}

/*
 * Domain
 */
resource "aws_apigatewayv2_domain_name" "default" {
  domain_name = "api.${local.domain}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = var.default_tags
}

resource "cloudflare_record" "api" {
  zone_id = cloudflare_zone.main.id
  name    = "api"
  type    = "CNAME"
  value   = aws_apigatewayv2_domain_name.default.domain_name_configuration.0.target_domain_name
  proxied = true
}

resource "aws_apigatewayv2_api_mapping" "default" {
  api_id          = aws_apigatewayv2_api.default.id
  domain_name     = aws_apigatewayv2_domain_name.default.id
  stage           = aws_apigatewayv2_stage.v1.id
  api_mapping_key = "v1"
}

/*
 * Origin Cert
 */
resource "tls_private_key" "api" {
  algorithm = "RSA"
}

resource "tls_cert_request" "api" {
  key_algorithm   = tls_private_key.api.algorithm
  private_key_pem = tls_private_key.api.private_key_pem

  dns_names = ["api.${local.domain}"]

  subject {
    common_name  = "api.${local.domain}"
    organization = "MediaCodex"
  }
}

resource "cloudflare_origin_ca_certificate" "api" {
  csr                = tls_cert_request.api.cert_request_pem
  hostnames          = ["api.${local.domain}"]
  request_type       = "origin-rsa"
  requested_validity = 5475 // (15yrs) Cloudflare default
}

resource "aws_acm_certificate" "api" {
  private_key       = tls_private_key.api.private_key_pem
  certificate_body  = cloudflare_origin_ca_certificate.api.certificate
  certificate_chain = file("../cloudflare_origin_root_ca.pem")
}

/*
 * Outputs
 */
output "gateway_id" {
  value       = aws_apigatewayv2_api.default.id
  description = "ID for primary API Gateway"
}

output "gateway_execution" {
  value       = aws_apigatewayv2_api.default.execution_arn
  description = "Invoke ARN of primary API Gateway"
}

output "authorizer_firebase" {
  value       = aws_apigatewayv2_authorizer.firebase.id
  description = "ID for firebase authorizer"
}
