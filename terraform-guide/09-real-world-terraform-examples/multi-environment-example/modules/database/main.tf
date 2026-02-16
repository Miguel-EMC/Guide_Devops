# modules/database/main.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-db-sg"
  description = "Security group for database in ${var.environment} environment"

  ingress {
    from_port       = 5432 # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = var.app_security_group_cidrs # Allow access from app servers
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_type
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true
  multi_az             = var.multi_az
  publicly_accessible  = false
  tags = {
    Name        = "${var.environment}-db-instance"
    Environment = var.environment
  }
}
