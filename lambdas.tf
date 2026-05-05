###############################################
# Lambda Permissions
###############################################

resource "aws_lambda_permission" "allow_apigw_invoke_create_order" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orders_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_eventbridge_order_created" {
  statement_id  = "AllowExecutionFromEventBridgeOrderCreated"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_created_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.order_created_rule.arn
}

###############################################
# create_order Lambda
###############################################

resource "aws_lambda_function" "create_order" {
  function_name = "${local.project}-create-order"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = "build/lambda_create_order.zip"
  source_code_hash = filebase64sha256("build/lambda_create_order.zip")

  

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST        = aws_rds_cluster.orders_cluster.endpoint
      DB_USER        = var.db_username
      DB_PASSWORD    = var.db_password
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.orders_bus.name
    }
  }
}

###############################################
# order_created_handler Lambda
###############################################

resource "aws_lambda_function" "order_created_handler" {
  function_name = "${local.project}-order-created-handler"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = "build/lambda_order_created_handler.zip"
  source_code_hash = filebase64sha256("build/lambda_order_created_handler.zip")

  

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST           = aws_rds_cluster.orders_cluster.endpoint
      DB_USER           = var.db_username
      DB_PASSWORD       = var.db_password
      PAYMENT_QUEUE_URL = aws_sqs_queue.payment_queue.url
    }
  }
}

###############################################
# payment_processor Lambda
###############################################

resource "aws_lambda_function" "payment_processor" {
  function_name = "${local.project}-payment-processor"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = "build/lambda_payment_processor.zip"
 source_code_hash = filebase64sha256("build/lambda_payment_processor.zip")
 
  

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST        = aws_rds_cluster.orders_cluster.endpoint
      DB_USER        = var.db_username
      DB_PASSWORD    = var.db_password
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.orders_bus.name
      SNS_TOPIC_ARN  = aws_sns_topic.order_notifications.arn
    }
  }
}
