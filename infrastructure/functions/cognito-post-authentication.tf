locals {
  function_name_cognito_post_authentication = "${var.prefix}cognito-post-authentication"
}

# ----------------------------------------------------------------------------------------------------------------------
# Function
# ----------------------------------------------------------------------------------------------------------------------
module "lambda_cogntio_post_authentication" {
  source = "../modules/lambda-function"

  aws_account = var.aws_account
  aws_region  = var.aws_region

  # handler
  name     = local.function_name_cognito_post_authentication
  filename = "${local.build_dir}/cognito-post-authentication.zip"

  environment_variables = merge(local.envvar_default, {
    "USER_SYNC_QUEUE_URL" = var.user_sync_queue_url
  })
}

resource "aws_lambda_permission" "cogntio_post_authentication" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_cogntio_post_authentication.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = var.cognito_pool_arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Permissions
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_cogntio_post_authentication_misc" {
  name   = "Misc"
  role   = module.lambda_cogntio_post_authentication.role_id
  policy = data.aws_iam_policy_document.lambda_cogntio_post_authentication_misc.json
}

data "aws_iam_policy_document" "lambda_cogntio_post_authentication_misc" {
  statement {
    sid = "SQS"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [var.user_sync_queue_arn]
  }
}
