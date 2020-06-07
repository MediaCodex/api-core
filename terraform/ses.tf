resource "aws_ses_domain_identity" "default" {
  domain = local.domain
}
resource "aws_ses_email_identity" "noreply" {
  provider = aws.eu-west-1
  email = "noreply@${local.domain}"
}


/*
 * Verification
 */
resource "cloudflare_record" "ses_verification" {
  zone_id = cloudflare_zone.main.id
  name    = "_amazonses"
  type    = "TXT"
  value   = aws_ses_domain_identity.default.verification_token
  ttl     = 600
}
resource "aws_ses_domain_identity_verification" "default" {
  domain     = aws_ses_domain_identity.default.id
  depends_on = [cloudflare_record.ses_verification]
}

/*
 * DKIM
 */
resource "aws_ses_domain_dkim" "default" {
  domain = aws_ses_domain_identity.default.domain
}
resource "cloudflare_record" "ses_dkim" {
  count = 3 // TODO: fix using for_each (TF race condition)

  zone_id = cloudflare_zone.main.id
  name    = "${element(aws_ses_domain_dkim.default.dkim_tokens, count.index)}._domainkey"
  type    = "CNAME"
  value   = "${element(aws_ses_domain_dkim.default.dkim_tokens, count.index)}.dkim.amazonses.com"
  ttl     = 600
}
