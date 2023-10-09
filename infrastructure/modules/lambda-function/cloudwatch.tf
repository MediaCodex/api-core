resource "aws_iam_role_policy" "cloudwatch" {
  name   = "Cloudwatch"
  role   = aws_iam_role.lambda_execution.name
  policy = data.aws_iam_policy_document.cloudwatch.json
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    sid = "LogGroup"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }

  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [join(":", [
      "arn:aws:logs",
      var.aws_region,
      var.aws_account,
      "log-group",
      "/aws/lambda/${aws_lambda_function.default.function_name}",
      "*"
    ])]
  }
}
