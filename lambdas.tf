resource "aws_lambda_permission" "allow_apigw_invoke_create_order" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orders_api.execution_arn}/*/*"
}

####create order lambda######
resource "aws_lambda_function" "create_order" {
  function_name = "${local.project}-create-order"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda_create_order.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.aurora_sg.id]
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

#######ordercreatedhandler Lambda#######
resource "aws_lambda_function" "order_created_handler" {
  function_name = "${local.project}-order-created-handler"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda_order_created_handler.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.aurora_sg.id]
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

#######payment processor Lambda#######
resource "aws_lambda_function" "payment_processor" {
  function_name = "${local.project}-payment-processor"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda_payment_processor.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.aurora_sg.id]
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

