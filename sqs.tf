# Dead-letter queue for failed payment messages
resource "aws_sqs_queue" "payment_dlq" {
  name = "${local.project}-payment-dlq"
}

# Main payment queue
resource "aws_sqs_queue" "payment_queue" {
  name = "${local.project}-payment-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_dlq.arn
    maxReceiveCount     = 5
  })
}

#######connecting SQS to Lambda#######
resource "aws_lambda_event_source_mapping" "payment_queue_trigger" {
  event_source_arn = aws_sqs_queue.payment_queue.arn
  function_name    = aws_lambda_function.payment_processor.arn
  batch_size       = 1
  enabled          = true
}
