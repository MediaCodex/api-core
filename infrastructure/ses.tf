locals {
  email_dmarc         = "dmarcreports@${cloudflare_zone.main.zone}"
  email_from          = "noreply@${cloudflare_zone.main.zone}"
  email_from_friendly = "MediaCodex <${local.email_from}>"
  email_domain        = cloudflare_zone.main.zone
  spf_includes = join(" ", [
    for s in concat(["amazonses.com"], var.email_spf_includes) : "include:${s}"
  ])
}

resource "aws_sesv2_email_identity" "domain" {
  email_identity = local.email_domain

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_sesv2_email_identity" "noreply" {
  email_identity = local.email_from

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }

  depends_on = [
    aws_sesv2_email_identity.domain,
    cloudflare_record.ses_dkim_domain[0],
    cloudflare_record.ses_dkim_domain[1],
    cloudflare_record.ses_dkim_domain[2]
  ]
}

resource "aws_ses_domain_mail_from" "default" {
  domain           = local.email_domain
  mail_from_domain = "bounce.${local.email_domain}"

  depends_on = [aws_sesv2_email_identity.domain]
}

resource "cloudflare_record" "ses_domain_mail_from_mx" {
  zone_id  = cloudflare_zone.main.id
  name     = aws_ses_domain_mail_from.default.mail_from_domain
  value    = "feedback-smtp.${var.aws_region}.amazonses.com"
  type     = "MX"
  ttl      = 600
  priority = 10
}

# ----------------------------------------------------------------------------------------------------------------------
# DKIM
# ----------------------------------------------------------------------------------------------------------------------
resource "cloudflare_record" "ses_dkim_domain" {
  count = 3

  zone_id = cloudflare_zone.main.id
  type    = "CNAME"
  ttl     = 600

  name = join(".", [
    element(aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens, count.index),
    "_domainkey.${local.email_domain}"
  ])

  value = join(".", [
    element(aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens, count.index),
    "dkim.amazonses.com"
  ])

  depends_on = [aws_sesv2_email_identity.domain]
}

# ----------------------------------------------------------------------------------------------------------------------
# SPF / DMARC
# ----------------------------------------------------------------------------------------------------------------------
resource "cloudflare_record" "ses_spf" {
  zone_id = cloudflare_zone.main.id
  type    = "TXT"
  name    = local.email_domain
  ttl     = 10800
  value   = "v=spf1 ${local.spf_includes} ~all"
}

resource "cloudflare_record" "ses_dmarc" {
  zone_id = cloudflare_zone.main.id
  type    = "TXT"
  name    = "_dmarc.${local.email_domain}"
  ttl     = 10800
  value   = "v=DMARC1;p=quarantine;pct=25;rua=mailto:${local.email_dmarc}"
}
