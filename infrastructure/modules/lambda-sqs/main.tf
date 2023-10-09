resource "aws_lambda_event_source_mapping" "sqs" {
  function_name    = var.function_name
  event_source_arn = var.queue_arn
  batch_size       = var.batch_size

  depends_on = [aws_iam_role_policy.sqs_event_source]
}

resource "aws_iam_role_policy" "sqs_event_source" {
  name   = "SQSEventSource"
  role   = var.function_role_name
  policy = data.aws_iam_policy_document.sqs_event_source.json
}

data "aws_iam_policy_document" "sqs_event_source" {
  statement {
    sid = "EventSourceMapping"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      var.queue_arn
    ]
  }
}