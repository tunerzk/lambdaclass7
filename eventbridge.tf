# Custom event bus for the order pipeline
resource "aws_cloudwatch_event_bus" "orders_bus" {
  name = "${local.project}-bus"
}

# Rule: When an order is created
resource "aws_cloudwatch_event_rule" "order_created_rule" {
  name           = "${local.project}-order-created"
  event_bus_name = aws_cloudwatch_event_bus.orders_bus.name

  event_pattern = jsonencode({
    source        = ["orders.api"]
    "detail-type" = ["OrderCreated"]
  })
}

# Rule: When an order is paid
resource "aws_cloudwatch_event_rule" "order_paid_rule" {
  name           = "${local.project}-order-paid"
  event_bus_name = aws_cloudwatch_event_bus.orders_bus.name

  event_pattern = jsonencode({
    source        = ["orders.payment"]
    "detail-type" = ["OrderPaid"]
  })

}

############eventbridge targets##############
# Target for OrderCreated → OrderCreatedHandler Lambda
resource "aws_cloudwatch_event_target" "order_created_target" {
  rule           = aws_cloudwatch_event_rule.order_created_rule.name
  event_bus_name = aws_cloudwatch_event_bus.orders_bus.name
  arn            = aws_lambda_function.order_created_handler.arn


}

# Target for OrderPaid → (later) PaymentProcessor or Notification Lambda
resource "aws_cloudwatch_event_target" "order_paid_target" {
  rule           = aws_cloudwatch_event_rule.order_paid_rule.name
  event_bus_name = aws_cloudwatch_event_bus.orders_bus.name
  arn            = aws_sns_topic.order_notifications.arn

}
