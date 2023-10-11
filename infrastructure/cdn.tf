locals {
  cdn_domain             = "cdn.${cloudflare_zone.main.zone}"
  cdn_buckets_ssm_prefix = "/cdn-buckets/"
  cdn_buckets = {
    for i, name in data.aws_ssm_parameters_by_path.asset_buckets.names :
    trimprefix(name, local.cdn_buckets_ssm_prefix) => data.aws_ssm_parameters_by_path.asset_buckets.values[i]
  }
}

data "aws_ssm_parameters_by_path" "asset_buckets" {
  path = local.cdn_buckets_ssm_prefix
  # ensure there is always at least one entry, IAM doesn't like empty resource blocks
  depends_on = [aws_ssm_parameter.cdn_avatars_bucket]
}

# ----------------------------------------------------------------------------------------------------------------------
# Cloudflare R2
# https://github.com/cloudflare/terraform-provider-cloudflare/issues/2537
# ----------------------------------------------------------------------------------------------------------------------
# resource "cloudflare_r2_bucket" "cdn_assets" {
#   account_id = var.cloudflare_account_id
#   name       = "mediacodex-${local.environment}-cdn-assets"
#   location   = "enam"
# }

# resource "cloudflare_record" "cdn" {
#   zone_id = cloudflare_zone.main.id
#   name    = local.cdn_domain
#   type    = "CNAME"
#   value   = aws_cloudfront_distribution.cdn_assets.domain_name
#   proxied = true
# }

resource "cloudflare_page_rule" "cdn" {
  zone_id = cloudflare_zone.main.id
  target  = "${local.cdn_domain}/*"

  actions {
    cache_level = "cache_everything"

    minify {
      html = "on"
      css  = "on"
      js   = "on"
    }
  }
}
