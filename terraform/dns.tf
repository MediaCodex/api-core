// NOTE: there are some records kept in other files so that they can more tightly
// grouped with their use-case, e.g. SES verification
resource "cloudflare_zone" "main" {
  zone = local.domain
}
resource "cloudflare_zone_settings_override" "main" {
  zone_id = cloudflare_zone.main.id
  settings {
    ssl                      = "strict"
    tls_1_3                  = "on"
    min_tls_version          = "1.2"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
  }
}

/*
 * Webmail
 */
resource "cloudflare_record" "webmail_mx10" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  value    = "spool.mail.gandi.net"
  ttl      = 10800
  priority = 10
}
resource "cloudflare_record" "webmail_mx50" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  value    = "fb.mail.gandi.net"
  ttl      = 10800
  priority = 50
}
resource "cloudflare_record" "webmail_spf" {
  zone_id = cloudflare_zone.main.id
  name    = "@"
  type    = "TXT"
  value   = "v=spf1 include:_mailcust.gandi.net include:amazonses.com ~all"
  ttl     = 10800
}
