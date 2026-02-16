# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "my-app-vpc"
    Environment = var.environment_tag
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${element(["a", "b"], count.index)}" # Dynamically pick AZ
  map_public_ip_on_launch = true
  tags = {
    Name        = "my-app-public-subnet-${count.index}"
    Environment = var.environment_tag
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${element(["a", "b"], count.index)}"
  tags = {
    Name        = "my-app-private-subnet-${count.index}"
    Environment = var.environment_tag
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "my-app-igw"
    Environment = var.environment_tag
  }
}

# Create NAT Gateway (one per public subnet for high availability)
resource "aws_eip" "nat" {
  count  = length(aws_subnet.public)
  domain = "vpc"
  tags = {
    Name        = "my-app-nat-eip-${count.index}"
    Environment = var.environment_tag
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name        = "my-app-nat-gw-${count.index}"
    Environment = var.environment_tag
  }
}

# Create Route Tables for public subnets
resource "aws_route_table" "public" {
  count  = length(aws_subnet.public)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name        = "my-app-public-rt-${count.index}"
    Environment = var.environment_tag
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Create Route Tables for private subnets
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id # Route traffic through NAT Gateway
  }
  tags = {
    Name        = "my-app-private-rt-${count.index}"
    Environment = var.environment_tag
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Basic Security Group for web servers (allows HTTP/HTTPS from anywhere)
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "my-app-web-sg"
  description = "Allow web traffic"

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
  tags = {
    Name        = "my-app-web-sg"
    Environment = var.environment_tag
  }
}
