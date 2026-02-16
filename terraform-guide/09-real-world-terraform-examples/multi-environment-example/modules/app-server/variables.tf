# modules/app-server/variables.tf
variable "vpc_id" {
  description = "The ID of the VPC to deploy into"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the app servers"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the app servers"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}
