# O banco só pode ser colocado nas subnets privadas (sem rota para a internet).
resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnets"
  description = "Subnets privadas do RDS"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.name}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  # Mantém a versão fixa: a AWS não troca a minor version por conta própria.
  auto_minor_version_upgrade = false

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = 0 # autoscaling de storage desligado (Free Tier)
  storage_type          = "gp3"
  # Cifra disco, snapshots e logs com a chave gerenciada aws/rds (KMS).
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  # Isolamento de rede: sem IP público, apenas em subnets privadas e aceitando
  # conexões só do SG do RDS (que por sua vez só aceita o SG da EC2).
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  # Restrições do Learner Lab / Free Tier.
  multi_az                     = false
  performance_insights_enabled = false
  monitoring_interval          = 0 # Enhanced Monitoring exige criar uma IAM role

  # Tudo destrutível sem intervenção manual.
  backup_retention_period  = var.backup_retention_period
  skip_final_snapshot      = true
  deletion_protection      = false
  delete_automated_backups = true

  apply_immediately = true

  tags = {
    Name = "${var.name}-postgres"
  }
}
