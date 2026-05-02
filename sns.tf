resource "aws_sns_topic" "order_notifications" {
  name = "${local.project}-notifications"
  tags = local.tags
}

####sns topic subscription for email notifications#####
resource "aws_sns_topic_subscription" "order_notifications_email" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email

  depends_on = [aws_sns_topic.order_notifications]


}
