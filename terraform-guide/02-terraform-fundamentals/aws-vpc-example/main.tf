# Specify the AWS provider
provider "aws" {
  region = var.aws_region
}

# Define an input variable for the AWS region
variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

# Define an input variable for the VPC CIDR block
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Create an AWS VPC resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "my-terraform-vpc"
    Environment = "development"
  }
}

# Output the VPC ID
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

# Output the VPC CIDR block
output "vpc_cidr" {
  description = "The CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}
