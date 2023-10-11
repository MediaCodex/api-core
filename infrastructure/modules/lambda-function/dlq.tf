resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                      = "lambda-${var.name}-dlq"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

# TODO: setup DLQ alarms
# resource "aws_cloudwatch_metric_alarm" "dlq_visible_messages" {
#   count = var.enable_dlq ? 1 : 0

#   alarm_name        = "${aws.aws_sqs_queue.dlq[0]}-visible-messages"
#   alarm_description = "${var.name} failed invocations DLQ messages"

#   namespace   = "AWS/SQS"
#   metric_name = "ApproximateNumberOfMessagesVisible"

#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   threshold           = 1
#   evaluation_periods  = 1
#   period              = 1
# }
