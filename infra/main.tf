locals {
  name = "${var.project}-${var.environment}"

  # Senha informada no tfvars tem precedência; senão, usa a gerada.
  db_password = coalesce(var.db_password, random_password.db.result)
}

# Senha gerada pelo Terraform: não aparece no código nem no tfvars (só no state,
# que é cifrado no S3). Sem "/", "@", "\"" e espaço, que o RDS proíbe, e sem
# caracteres que o shell ou o --env-file do Docker interpretariam.
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "-_"
}

module "vpc" {
  source = "./modules/vpc"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_group" {
  source = "./modules/security-group"

  name             = local.name
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
  api_port         = var.api_port
}

module "rds" {
  source = "./modules/rds"

  name               = local.name
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_group.rds_sg_id

  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = local.db_password
}

module "ec2" {
  source = "./modules/ec2"

  name          = local.name
  aws_region    = var.aws_region
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]
  ec2_sg_id     = module.security_group.ec2_sg_id
  key_name      = var.key_name

  app_repo_url = var.app_repo_url
  app_repo_ref = var.app_repo_ref
  app_dir      = var.app_dir
  api_port     = var.api_port

  # Os dados de conexão vêm dos outputs do RDS, o que também faz a EC2
  # ser criada só depois que o banco estiver disponível.
  db_host     = module.rds.db_address
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_username = var.db_username
  db_password = local.db_password
}
