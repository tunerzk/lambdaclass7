# Custom event bus for the order pipeline
resource "aws_eventbridge_bus" "orders_bus" {
  name = "${local.project}-bus"
}

# Rule: When an order is created
resource "aws_eventbridge_rule" "order_created_rule" {
  name           = "${local.project}-order-created"
  event_bus_name = aws_eventbridge_bus.orders_bus.name

  event_pattern = jsonencode({
    "detail-type" : ["OrderCreated"]
  })
}

# Rule: When an order is paid
resource "aws_eventbridge_rule" "order_paid_rule" {
  name           = "${local.project}-order-paid"
  event_bus_name = aws_eventbridge_bus.orders_bus.name

  event_pattern = jsonencode({
    "detail-type" : ["OrderPaid"]
  })
}

############eventbridge targets##############
# Target for OrderCreated → OrderCreatedHandler Lambda
resource "aws_eventbridge_target" "order_created_target" {
  rule           = aws_eventbridge_rule.order_created_rule.name
  event_bus_name = aws_eventbridge_bus.orders_bus.name
  arn            = aws_lambda_function.order_created_handler.arn
}

# Target for OrderPaid → (later) PaymentProcessor or Notification Lambda
resource "aws_eventbridge_target" "order_paid_target" {
  rule           = aws_eventbridge_rule.order_paid_rule.name
  event_bus_name = aws_eventbridge_bus.orders_bus.name
  arn            = aws_lambda_function.payment_processor.arn
}
