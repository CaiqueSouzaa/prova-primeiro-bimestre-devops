# Os SGs são criados sem regras inline; cada regra é um recurso separado.
# Assim as referências cruzadas (RDS -> EC2) não criam ciclo, e o Terraform
# remove a regra de saída "allow all" que a AWS cria por padrão.

# ---------- SG da EC2 (API) ----------
resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "API: SSH restrito ao IP do operador e porta ${var.api_port} publica"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-ec2-sg"
  }
}

# SSH só a partir de um único IP (/32): a porta 22 nunca fica aberta para a internet.
resource "aws_security_group_rule" "ec2_ssh" {
  type              = "ingress"
  description       = "SSH somente do IP do operador"
  security_group_id = aws_security_group.ec2.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [var.allowed_ssh_cidr]
}

# A API é o serviço público, então esta é a única porta aberta para 0.0.0.0/0.
resource "aws_security_group_rule" "ec2_api" {
  type              = "ingress"
  description       = "API HTTP publica"
  security_group_id = aws_security_group.ec2.id
  protocol          = "tcp"
  from_port         = var.api_port
  to_port           = var.api_port
  cidr_blocks       = ["0.0.0.0/0"]
}

# Saída liberada: a EC2 precisa baixar pacotes (dnf), o código (git), imagens
# Docker e o bundle de CA do RDS, além de falar com o banco.
resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  description       = "Saida liberada"
  security_group_id = aws_security_group.ec2.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# ---------- SG do RDS ----------
# Sem nenhuma regra de saída: o banco só responde conexões, nunca as inicia.
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "PostgreSQL acessivel apenas a partir do SG da EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

# Única entrada do banco: a origem é o SG da EC2, não um CIDR. Só instâncias
# associadas a esse SG alcançam a 5432; a regra continua valendo se o IP da EC2
# mudar, e nenhum outro recurso da VPC ganha acesso por estar na mesma faixa de IP.
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  description              = "PostgreSQL somente a partir do SG da EC2"
  security_group_id        = aws_security_group.rds.id
  protocol                 = "tcp"
  from_port                = var.db_port
  to_port                  = var.db_port
  source_security_group_id = aws_security_group.ec2.id
}
