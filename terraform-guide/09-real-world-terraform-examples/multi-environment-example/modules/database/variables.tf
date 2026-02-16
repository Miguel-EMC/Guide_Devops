# modules/database/variables.tf
variable "vpc_id" {
  description = "The ID of the VPC to deploy into"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the database"
  type        = list(string)
}

variable "db_allocated_storage" {
  description = "RDS DB allocated storage in GB"
  type        = number
}

variable "db_instance_type" {
  description = "RDS DB instance type"
  type        = string
}

variable "db_engine_version" {
  description = "RDS DB engine version"
  type        = string
}

variable "db_name" {
  description = "RDS DB name"
  type        = string
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

variable "multi_az" {
  description = "Whether to deploy the DB in Multi-AZ"
  type        = bool
  default     = false
}

variable "app_security_group_cidrs" {
  description = "List of CIDR blocks from which app servers can connect to the DB"
  type        = list(string)
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}
