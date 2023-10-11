locals {
  function_name_eventbridge_sync_cdn = "${var.prefix}eventbridge-sync-cdn"
}

# ----------------------------------------------------------------------------------------------------------------------
# Function
# ----------------------------------------------------------------------------------------------------------------------
module "lambda_eventbridge_sync_cdn" {
  source = "../modules/lambda-function"

  aws_account = var.aws_account
  aws_region  = var.aws_region

  name       = local.function_name_eventbridge_sync_cdn
  filename   = "${local.build_dir}/eventbridge-sync-cdn.zip"
  enable_dlq = true

  environment_variables = merge(local.envvar_default, {
    "CDN_BUCKET_MAPPING" = jsonencode(var.cdn_buckets_map)
  })
}

resource "aws_lambda_permission" "eventbridge_sync_cdn" {
  statement_id  = "AllowEventbridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_cogntio_post_authentication.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cdn_sync.arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Permissions
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_eventbridge_sync_cdn_misc" {
  name   = "Misc"
  role   = module.lambda_eventbridge_sync_cdn.role_id
  policy = data.aws_iam_policy_document.lambda_eventbridge_sync_cdn_misc.json
}

data "aws_iam_policy_document" "lambda_eventbridge_sync_cdn_misc" {
  statement {
    sid = "S3"

    actions = [
      "s3:GetObject",
      "s3:PutObjectVersionTagging"
    ]

    resources = [
      for dir, bucket in var.cdn_buckets_map : "arn:aws:s3:::${bucket}/*"
    ]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# EventBridge rules
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "cdn_sync" {
  name           = "sync-assets-to-cloudflare"
  description    = "Sync S3 objects to Cloudflare"
  event_bus_name = var.cdn_event_bus

  event_pattern = jsonencode({
    "source"      = ["aws.s3"],
    "detail-type" = ["Object Created"],
    "detail" = {
      "bucket" = {
        "name" = [
          for k, v in var.cdn_buckets_map : v
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "cdn_sync" {
  event_bus_name = var.cdn_event_bus
  rule           = aws_cloudwatch_event_rule.cdn_sync.name
  target_id      = "SendToLambda"
  arn            = module.lambda_eventbridge_sync_cdn.function_arn
}
