variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The ID of an existing VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "mywebapp"
}

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "RDS DB instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS DB allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "RDS DB engine version"
  type        = string
  default     = "13.6"
}

variable "db_username" {
  description = "RDS DB master username"
  type        = string
}

variable "db_password" {
  description = "RDS DB master password"
  type        = string
  sensitive   = true
}
