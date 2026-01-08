# RDS PostgreSQL module for the SaaS Platform
# This module creates a PostgreSQL database instance for the multi-tenant application

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.environment}-postgres-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.environment}-postgres-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.environment}-postgres-parameter-group"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name        = "${var.environment}-postgres-parameter-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "postgres" {
  name_prefix = "${var.environment}-postgres-"
  description = "Security group for PostgreSQL RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-postgres-sg"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.environment}-postgres"

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = 5432

  instance_class = var.instance_class

  engine         = "postgres"
  engine_version = "14.9"
  allocated_storage = var.storage_size
  storage_type     = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  parameter_group_name = aws_db_parameter_group.postgres.name

  multi_az = var.multi_az

  backup_retention_period = var.backup_retention
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  skip_final_snapshot = var.skip_final_snapshot

  tags = {
    Name        = "${var.environment}-postgres"
    Environment = var.environment
    Application = "multitenant-api"
  }

  depends_on = [
    aws_db_subnet_group.postgres,
    aws_db_parameter_group.postgres,
  ]
}