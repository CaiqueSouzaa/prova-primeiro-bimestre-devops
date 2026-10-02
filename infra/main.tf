# main.tf (ROOT) — Composição dos módulos

# ========================================
# 1. VPC (base de tudo)
# ========================================
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
  subnets      = var.subnets
}

# ========================================
# 2. Security Groups (vpc_id ← módulo VPC)
# ========================================
module "api_sg" {
  source = "./modules/security-group"

  name         = "${var.project_name}-${var.environment}-api-sg"
  description  = "API - SSH e porta 3000"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  ingress_rules = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH" },
    { from_port = var.api_port, to_port = var.api_port, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "API Node.js" },
  ]
}

module "rds_sg" {
  source = "./modules/security-group"

  name         = "${var.project_name}-${var.environment}-rds-sg"
  description  = "RDS - PostgreSQL apenas do SG da EC2"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  # Permite conexão APENAS do Security Group da EC2 (menor privilégio)
  ingress_rules = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.api_sg.sg_id
      description              = "PostgreSQL apenas do SG da API"
    },
  ]
}

# ========================================
# 3. RDS (subnets privadas ← VPC, SG ← rds_sg)
# ========================================
module "database" {
  source = "./modules/rds"

  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]
  instance_class     = var.db_instance_class
  environment        = var.environment
  project_name       = var.project_name
}

# ========================================
# 4. EC2 (subnet ← VPC, SG ← api_sg, conexão ← RDS)
# ========================================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name        = "${var.project_name}-${var.environment}-key"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

module "api_server" {
  source = "./modules/ec2"

  instance_name        = "${var.project_name}-${var.environment}-api"
  instance_type        = var.instance_type
  ami_id               = data.aws_ami.amazon_linux.id
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.api_sg.sg_id]
  key_name             = aws_key_pair.this.key_name
  iam_instance_profile = "LabInstanceProfile" # pré-existente no Learner Lab, NÃO criar role
  environment          = var.environment
  project_name         = var.project_name

  # Sobe a API de Reservas (app/Dockerfile) apontando para o RDS (← outputs do módulo database)
  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee -a /var/log/reservas-setup.log) 2>&1
    echo "[setup] início"

    # t2.micro tem 1 GB de RAM: sem swap o build da imagem (npm ci + nest build) estoura a memória
    dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    dnf install -y docker git postgresql15
    systemctl enable --now docker

    mkdir -p /opt/reservas/certs
    git clone --depth 1 ${var.app_repo_url} /opt/reservas/src

    # RDS PostgreSQL 15 exige SSL: CA do RDS para a API validar o certificado do banco
    curl -fsSL https://truststore.pki.rds.amazonaws.com/${var.aws_region}/${var.aws_region}-bundle.pem -o /opt/reservas/certs/rds-ca.pem

    install -m 600 /dev/null /opt/reservas/app.env
    cat > /opt/reservas/app.env <<'ENV'
    PORT=${var.api_port}
    DB_HOST=${module.database.db_address}
    DB_PORT=${module.database.db_port}
    DB_DATABASE=${module.database.db_name}
    DB_USERNAME=${var.db_username}
    DB_PASSWORD=${var.db_password}
    ORM_LOGGING=false
    ORM_SYNCHRONIZE=false
    PGSSLMODE=require
    NODE_EXTRA_CA_CERTS=/certs/rds-ca.pem
    ENV

    docker build -t reservas-api /opt/reservas/src/app
    docker run -d --name reservas-api --restart unless-stopped \
      --env-file /opt/reservas/app.env \
      -v /opt/reservas/certs:/certs:ro \
      -p ${var.api_port}:${var.api_port} \
      reservas-api

    echo "[setup] fim"
  EOF
}
