resource "aws_iam_role" "lambda_exec" {
  name = "${local.project}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#####lambda permissions for EventBridge#####
resource "aws_lambda_permission" "allow_eventbridge_invoke_order_created" {
  statement_id  = "AllowEventBridgeInvokeOrderCreated"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_created_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.order_created_rule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_order_paid" {
  statement_id  = "AllowEventBridgeInvokeOrderPaid"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.order_paid_rule.arn
}

##sqs permissions for Lambda#########
resource "aws_lambda_permission" "allow_sqs_invoke_payment_processor" {
  statement_id  = "AllowSQSTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_processor.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.payment_queue.arn
}

#########lambda to sns permissions#########
resource "aws_iam_policy" "lambda_publish_sns" {
  name        = "${local.project}-lambda-publish-sns"
  description = "Allow Lambdas to publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.order_notifications.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_publish_sns_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_publish_sns.arn
}

###evenbridge putevents permissions for Lambda#######
resource "aws_iam_policy" "lambda_eventbridge_put" {
  name        = "${local.project}-lambda-eventbridge-put"
  description = "Allow Lambdas to put events on EventBridge bus"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "events:PutEvents"
      Resource = aws_cloudwatch_event_bus.orders_bus.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_eventbridge_put_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_eventbridge_put.arn
}

####sqs sendmessage permissions for Lambda#####
resource "aws_iam_policy" "lambda_sqs_send" {
  name        = "${local.project}-lambda-sqs-send"
  description = "Allow Lambdas to send messages to SQS queues"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.payment_queue.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_send_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_send.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
