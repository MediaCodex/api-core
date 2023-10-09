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
  cdn_bucket_name              = ""
  cdn_domain                   = ""

  environment = {}

  ddb_table_arns = {
    users = aws_dynamodb_table.users.arn
  }

  ddb_table_names = {
    users = aws_dynamodb_table.users.id
  }
}


