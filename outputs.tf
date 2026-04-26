output "bucket" { value = aws_s3_bucket.imagesbucks3 }

output "db_endpoint" {
  value = aws_rds_cluster.orders_cluster.endpoint
}

output "db_reader_endpoint" {
  value = aws_rds_cluster.orders_cluster.reader_endpoint
}

output "sns_topic_arn" {
  value = aws_sns_topic.order_notifications.arn
}
