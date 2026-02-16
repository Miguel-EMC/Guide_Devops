# environments/staging/main.tf
module "vpc" {
  source = "../../modules/vpc"

  aws_region          = "us-east-1"
  cidr_block          = "10.2.0.0/16"
  public_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24"]
  environment         = "staging"
}

module "app_server" {
  source = "../../modules/app-server"

  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  instance_type = "t3.medium"
  environment   = "staging"
}

module "database" {
  source = "../../modules/database"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnet_ids # For simplicity, placing in public for staging
  db_allocated_storage     = 50
  db_instance_type         = "db.t3.medium"
  db_engine_version        = "13.6"
  db_name                  = "stagingdb"
  db_username              = "staginguser"
  db_password              = var.db_password # From tfvars
  multi_az                 = true
  app_security_group_cidrs = ["0.0.0.0/0"] # For simplicity in staging, restrict in prod
  environment              = "staging"
}

variable "db_password" {
  description = "Database password for staging environment"
  type        = string
  sensitive   = true
}
