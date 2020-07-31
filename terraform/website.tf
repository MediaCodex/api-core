/*
 * DNS
 */
resource "cloudflare_record" "website" {
  count   = var.first_deploy == true ? 0 : 1
  zone_id = cloudflare_zone.main.id
  name    = "@"
  type    = "CNAME"
  value   = data.terraform_remote_state.website.outputs.cloudfront_domain
  proxied = true
}

resource "cloudflare_record" "website_www" {
  count   = var.first_deploy == true ? 0 : 1
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
  provider          = aws.us_east_1
  domain_name       = local.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.default_tags
}

resource "cloudflare_record" "website_cert" {
  for_each = {
    for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
      resource_record_name   = dvo.resource_record_name
      resource_record_value = dvo.resource_record_value
      resource_record_type   = dvo.resource_record_type
    }
  }

  zone_id = cloudflare_zone.main.id
  proxied = false

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  value   = trimsuffix(each.value.resource_record_value, ".")
}

resource "aws_acm_certificate_validation" "website" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for record in cloudflare_record.website_cert: record.hostname]
}

/*
 * Outputs
 */
output "website_cert" {
  value       = aws_acm_certificate.website.arn
  description = "ARN of ACM cert for website origin"
}
