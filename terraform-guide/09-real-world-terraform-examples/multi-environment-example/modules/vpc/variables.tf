# modules/vpc/variables.tf
variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}
