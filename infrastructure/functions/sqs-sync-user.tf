locals {
  function_name_sqs_sync_user = "${var.prefix}sqs-sync-user"
}

# ----------------------------------------------------------------------------------------------------------------------
# Function
# ----------------------------------------------------------------------------------------------------------------------
module "lambda_sqs_sync_user" {
  source = "../modules/lambda-function"

  aws_account = var.aws_account
  aws_region  = var.aws_region

  name     = local.function_name_sqs_sync_user
  filename = "${local.build_dir}/sqs-sync-user.zip"

  environment_variables = merge(local.envvar_default, {
    "COGNITO_USER_POOL_ID" = var.cognito_pool_id
    "USER_SYNC_QUEUE_URL"  = var.user_sync_queue_url
    "CDN_S3_BUCKET"        = var.cdn_bucket_name
    "CDN_DOMAIN"           = var.cdn_domain
  })
}

module "sqs_lambda_sqs_sync_user" {
  source = "../modules/lambda-sqs"

  queue_arn          = var.user_sync_queue_arn
  function_name      = module.lambda_sqs_sync_user.function_name
  function_role_name = module.lambda_sqs_sync_user.role_arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Permissions
# ----------------------------------------------------------------------------------------------------------------------
module "lambda_sqs_sync_user_dynamodb" {
  source = "../modules/iam-dynamodb"
  role   = module.lambda_sqs_sync_user.role_id

  tables = [{
    arn          = var.ddb_table_arns.users
    enable_write = true
  }]
}

resource "aws_iam_role_policy" "lambda_sqs_sync_user_misc" {
  name   = "Misc"
  role   = module.lambda_sqs_sync_user.role_id
  policy = data.aws_iam_policy_document.lambda_sqs_sync_user_misc.json
}

data "aws_iam_policy_document" "lambda_sqs_sync_user_misc" {
  statement {
    sid = "Cognito"

    actions = [
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminUpdateUserAttributes"
    ]

    resources = [var.cognito_pool_arn]
  }

  statement {
    sid = "S3"

    actions = [
      "s3:PutObject"
    ]

    resources = ["arn:aws:s3:::${var.cdn_bucket_name}/avatar/*"]
  }
}
