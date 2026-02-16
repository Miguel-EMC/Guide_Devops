# environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"

  aws_region          = "us-east-1"
  cidr_block          = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  environment         = "dev"
}

module "app_server" {
  source = "../../modules/app-server"

  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  instance_type = "t3.micro"
  environment   = "dev"
}

module "database" {
  source = "../../modules/database"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnet_ids # For simplicity, placing in public for dev
  db_allocated_storage     = 20
  db_instance_type         = "db.t3.micro"
  db_engine_version        = "13.6"
  db_name                  = "devdb"
  db_username              = "devuser"
  db_password              = var.db_password # From tfvars
  multi_az                 = false
  app_security_group_cidrs = ["0.0.0.0/0"] # For simplicity in dev, restrict in prod
  environment              = "dev"
}

variable "db_password" {
  description = "Database password for dev environment"
  type        = string
  sensitive   = true
}
