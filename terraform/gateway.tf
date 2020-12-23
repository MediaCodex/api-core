/**
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

/**
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

/**
 * SSM Outputs
 */
resource "aws_ssm_parameter" "gateway_public_domain" {
  name  = "/gateway-public/domain"
  type  = "String"
  value = aws_apigatewayv2_domain_name.default.id
  tags  = var.default_tags
}
