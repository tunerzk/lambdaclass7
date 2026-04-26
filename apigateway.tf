resource "aws_apigatewayv2_api" "orders_api" {
  name          = "${local.project}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.orders_api.id
  name        = "$default"
  auto_deploy = true
}

# POST /orders route
resource "aws_apigatewayv2_route" "create_order_route" {
  api_id    = aws_apigatewayv2_api.orders_api.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.create_order_integration.id}"
}

# Lambda integration
resource "aws_apigatewayv2_integration" "create_order_integration" {
  api_id                 = aws_apigatewayv2_api.orders_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_order.invoke_arn
  payload_format_version = "2.0"
}
