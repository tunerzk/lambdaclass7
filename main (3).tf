# Lab 1 Starter Terraform
provider "aws" { region = var.region }

resource "aws_s3_bucket" "images" {
  bucket = "${var.project}-images"
}

# TODO: Add Lambda, EventBridge rule, Aurora cluster, SNS topic
