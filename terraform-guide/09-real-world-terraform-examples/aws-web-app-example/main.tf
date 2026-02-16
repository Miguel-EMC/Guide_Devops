# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

# --- Security Groups ---
resource "aws_security_group" "alb_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP/HTTPS access to ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.app_name}-alb-sg" }
}

resource "aws_security_group" "app_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.app_name}-app-sg"
  description = "Allow traffic from ALB and egress to DB"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.app_name}-app-sg" }
}

resource "aws_security_group" "db_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.app_name}-db-sg"
  description = "Allow traffic from app servers"

  ingress {
    from_port       = 5432 # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.app_name}-db-sg" }
}

# --- Application Load Balancer (ALB) ---
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids # ALB typically in public subnets

  enable_deletion_protection = false # Set to true for production

  tags = { Name = "${var.app_name}-alb" }
}

resource "aws_lb_target_group" "main" {
  name        = "${var.app_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance" # For EC2 instances

  health_check {
    path                = "/" # Adjust to your app's health check endpoint
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${var.app_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# --- Auto Scaling Group (ASG) for EC2 instances ---
resource "aws_launch_template" "main" {
  name_prefix   = "${var.app_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = "your-key-pair" # IMPORTANT: Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              # Your application startup commands here
              EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.app_name}-instance"
    }
  }
  tags = { Name = "${var.app_name}-lt" }
}

resource "aws_autoscaling_group" "main" {
  name                      = "${var.app_name}-asg"
  vpc_zone_identifier       = var.private_subnet_ids # App servers in private subnets
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300 # seconds

  launch_template {
    id      = aws_launch_template.main.id
    version = "$$Latest"
  }

  target_group_arns = [aws_lb_target_group.main.arn]
  tags = [
    {
      key                 = "Name"
      value               = "${var.app_name}-asg-instance"
      propagate_at_launch = true
    },
  ]
}

# --- RDS PostgreSQL Database ---
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids # DB in private subnets
  tags = { Name = "${var.app_name}-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp2" # General Purpose SSD
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_type
  name                 = var.app_name # Database name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres13"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true # Set to false for production
  multi_az             = true # For high availability
  publicly_accessible  = false # Crucial for security
  tags = { Name = "${var.app_name}-db-instance" }
}
