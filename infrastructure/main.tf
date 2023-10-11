module "functions" {
  source = "./functions"

  aws_account = local.aws_account
  aws_region  = var.aws_region

  prefix                       = local.prefix
  cognito_pool_id              = aws_cognito_user_pool.main.id
  cognito_pool_arn             = aws_cognito_user_pool.main.arn
  email_allowed_from_addresses = [local.email_from, local.email_from_friendly]
  user_sync_queue_arn          = aws_sqs_queue.user_sync.arn
  user_sync_queue_url          = aws_sqs_queue.user_sync.url
  avatars_bucket               = aws_s3_bucket.avatars.id
  cdn_buckets_map              = local.cdn_buckets

  environment = {
    "CDN_R2_BUCKET" = "mediacodex-${local.environment}-cdn-assets" # cloudflare_r2_bucket.cdn_assets.name
    "CDN_DOMAIN"    = "cdn.${local.domain}" # cloudflare_record.cdn.name
  }

  ddb_table_arns = {
    users = aws_dynamodb_table.users.arn
  }

  ddb_table_names = {
    users = aws_dynamodb_table.users.id
  }
}


