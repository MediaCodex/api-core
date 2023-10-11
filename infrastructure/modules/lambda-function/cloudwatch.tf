resource "aws_iam_role_policy" "cloudwatch" {
  name   = "Monitoring"
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

  # DLQ SendMessage
  dynamic "statement" {
    for_each = var.enable_dlq ? ["enabled"] : []
    content {
      sid = "SendMessageDLQ"
      actions = [
        "sqs:SendMessage"
      ]
      resources = [
        aws_sqs_queue.dlq[0].arn
      ]
    }
  }
}
