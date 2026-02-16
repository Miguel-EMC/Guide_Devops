# modules/app-server/main.tf
resource "aws_security_group" "app_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-app-sg"
  description = "Security group for app servers in ${var.environment} environment"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In a real scenario, restrict to ALB SG
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0] # Place in the first provided subnet
  security_groups = [aws_security_group.app_sg.id]

  tags = {
    Name        = "${var.environment}-app-server"
    Environment = var.environment
  }
}
