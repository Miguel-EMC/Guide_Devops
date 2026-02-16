# environments/prod/main.tf
module "vpc" {
  source = "../../modules/vpc"

  aws_region          = "us-east-1"
  cidr_block          = "10.3.0.0/16"
  public_subnet_cidrs = ["10.3.1.0/24", "10.3.2.0/24"]
  environment         = "prod"
}

module "app_server" {
  source = "../../modules/app-server"

  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  instance_type = "m5.large"
  environment   = "prod"
}

module "database" {
  source = "../../modules/database"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnet_ids # For simplicity, placing in public for prod
  db_allocated_storage     = 100
  db_instance_type         = "db.r5.large"
  db_engine_version        = "13.6"
  db_name                  = "proddb"
  db_username              = "produser"
  db_password              = var.db_password # From tfvars
  multi_az                 = true
  app_security_group_cidrs = ["0.0.0.0/0"] # For simplicity in prod, restrict this properly
  environment              = "prod"
}

variable "db_password" {
  description = "Database password for prod environment"
  type        = string
  sensitive   = true
}
