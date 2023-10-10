locals {
  cdn_domain    = "cdn.${cloudflare_zone.main.zone}"
  cdn_s3_origin = "s3_cdn_assets"
}

resource "aws_s3_bucket" "cdn_assets" {
  bucket_prefix = "cdn-assets-"
}

resource "aws_s3_bucket_ownership_controls" "cdn_assets" {
  bucket = aws_s3_bucket.cdn_assets.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "cdn_assets" {
  bucket = aws_s3_bucket.cdn_assets.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_website_configuration" "cdn_assets" {
  bucket = aws_s3_bucket.cdn_assets.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "cdn_assets" {
  bucket = aws_s3_bucket.cdn_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Don't modify this bucket in two ways at the same time, S3 API will complain.
  depends_on = [aws_s3_bucket_policy.cloudfront]
}

resource "aws_s3_bucket_cors_configuration" "cdn_assets" {
  bucket = aws_s3_bucket.cdn_assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["HEAD", "GET"]
    allowed_origins = ["https://${cloudflare_zone.main.zone}"]
    # expose_headers  = ["ETag"]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Cloudfront access
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.cdn_assets.id
  policy = data.aws_iam_policy_document.s3_policy_cloudfront.json
}

data "aws_iam_policy_document" "s3_policy_cloudfront" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.cdn_assets.arn,
      "${aws_s3_bucket.cdn_assets.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cdn_assets.iam_arn]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Cloudfront
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "cdn_assets" {
  comment = "CDN Assets"
}

resource "aws_cloudfront_distribution" "cdn_assets" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  aliases = [local.cdn_domain]

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.cdn.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  origin {
    domain_name = aws_s3_bucket.cdn_assets.bucket_regional_domain_name
    origin_id   = local.cdn_s3_origin

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cdn_assets.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = local.cdn_s3_origin
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "allow-all"

    # TTL
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [
    aws_acm_certificate.cdn,
    aws_acm_certificate_validation.cdn
  ]
}

resource "aws_acm_certificate" "cdn" {
  domain_name       = local.cdn_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "cdn_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cdn.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = cloudflare_zone.main.id
  type    = each.value.type
  name    = trimsuffix(each.value.name, ".")
  value   = trimsuffix(each.value.record, ".")
  proxied = false
}

resource "aws_acm_certificate_validation" "cdn" {
  certificate_arn         = aws_acm_certificate.cdn.arn
  validation_record_fqdns = [for record in cloudflare_record.cdn_cert_validation : record.hostname]
}

resource "cloudflare_record" "cdn" {
  zone_id = cloudflare_zone.main.id
  name    = local.cdn_domain
  type    = "CNAME"
  value   = aws_cloudfront_distribution.cdn_assets.domain_name
  proxied = true
}
