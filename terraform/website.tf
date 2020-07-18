/*
 * DNS
 */
resource "cloudflare_record" "website" {
  count = var.first_deploy == true ? 0 : 1
  zone_id = cloudflare_zone.main.id
  name    = "@"
  type    = "CNAME"
  value   = "${local.domain}.s3-website.eu-central-1.amazonaws.com"
  proxied = true
}

resource "cloudflare_record" "website_www" {
  count = var.first_deploy == true ? 0 : 1
  zone_id = cloudflare_zone.main.id
  name    = "www"
  type    = "CNAME"
  value   = cloudflare_record.website.0.hostname
  proxied = true
}

/*
 * Origin Cert
 */
resource "aws_acm_certificate" "website" {
  provider = aws.us_east_1
  domain_name       = local.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.default_tags
}

resource "cloudflare_record" "website_cert" {
  zone_id = cloudflare_zone.main.id
  name    = aws_acm_certificate.website.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.website.domain_validation_options.0.resource_record_type
  value   = trimsuffix(aws_acm_certificate.website.domain_validation_options.0.resource_record_value, ".")
  proxied = false
}

resource "aws_acm_certificate_validation" "website" {
  provider = aws.us_east_1
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [cloudflare_record.website_cert.hostname]
}

/*
 * Outputs
 */
output "website_cert" {
  value       = aws_acm_certificate.website.arn
  description = "ARN of ACM cert for website origin"
}
