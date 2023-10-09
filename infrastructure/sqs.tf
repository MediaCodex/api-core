resource "aws_sqs_queue" "user_sync" {
  name                      = "${local.prefix}user-sync"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}
