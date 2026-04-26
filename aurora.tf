resource "aws_vpc" "main" {
  cidr_block = "10.126.0.0/16"
  tags       = local.tags
}

###################private subnets for Aurora###################
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.126.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false
  tags                    = local.tags
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.126.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false
  tags                    = local.tags
}

########security group for Aurora allowing access from Lambda########
resource "aws_security_group" "aurora_sg" {
  name        = "${local.project}-aurora-sg"
  description = "Allow Lambda access to Aurora"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.126.0.0/16"] # allow VPC internal traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

#aurora subnet group for cluster#############################
resource "aws_rds_cluster_subnet_group" "aurora_subnets" {
  name = "${local.project}-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = local.tags
}

#########aurora cluster with MySQL engine#########################
resource "aws_rds_cluster" "orders_cluster" {
  cluster_identifier = "${local.project}-cluster"
  engine             = "aurora-mysql"
  engine_mode        = "provisioned"

  database_name   = "orders"
  master_username = var.db_username
  master_password = var.db_password

  db_subnet_group_name   = aws_rds_cluster_subnet_group.aurora_subnets.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }

  skip_final_snapshot = true
  tags                = local.tags
}

######aurora cluster instance for connectivity testing################
resource "aws_rds_cluster_instance" "orders_instance" {
  identifier          = "${local.project}-instance"
  cluster_identifier  = aws_rds_cluster.orders_cluster.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.orders_cluster.engine
  publicly_accessible = false
  tags                = local.tags
}