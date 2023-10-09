resource "cloudflare_zone" "main" {
  account_id = var.cloudflare_account_id
  zone       = local.domain
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

# ----------------------------------------------------------------------------------------------------------------------
# SSM outputs
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "dns_zone" {
  name  = "/cloudflare-zones/main"
  type  = "String"
  value = cloudflare_zone.main.id
}