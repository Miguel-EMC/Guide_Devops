# main.tf for AWS EC2
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "terraform-example-vpc" }
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "terraform-example-subnet" }
}

resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.example.id
  name        = "web-access"
  description = "Allow web traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example.id
  security_groups = [aws_security_group.web_sg.id]

  tags = {
    Name = "HelloWorldWebServer"
  }
}

output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}
