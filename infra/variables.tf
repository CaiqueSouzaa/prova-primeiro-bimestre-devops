variable "aws_region" {
  description = "Região AWS. O AWS Academy Learner Lab só permite us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome do projeto (prefixo dos recursos e tag Project)."
  type        = string
  default     = "reservas"
}

variable "environment" {
  description = "Nome do ambiente (tag Environment)."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Responsável pelos recursos (tag Owner)."
  type        = string
}

# ---------- Rede ----------
variable "vpc_cidr" {
  description = "CIDR da VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "AZs usadas pelas subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas (uma por AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (uma por AZ)."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "Seu IP público no formato x.x.x.x/32; único endereço com acesso SSH."
  type        = string
}

# ---------- EC2 / API ----------
variable "instance_type" {
  description = "Tipo da instância EC2."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair existente no Learner Lab."
  type        = string
  default     = "vockey"
}

variable "api_port" {
  description = "Porta da API."
  type        = number
  default     = 3000
}

variable "app_repo_url" {
  description = "Repositório Git público do projeto."
  type        = string
  default     = "https://github.com/CaiqueSouzaa/prova-primeiro-bimestre-devops.git"
}

variable "app_repo_ref" {
  description = "Branch ou tag implantada."
  type        = string
  default     = "main"
}

variable "app_dir" {
  description = "Diretório do repositório que contém o Dockerfile da API."
  type        = string
  default     = "app"
}

# ---------- RDS ----------
variable "db_engine_version" {
  description = "Versão fixa do PostgreSQL."
  type        = string
  default     = "16.15"
}

variable "db_instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nome do banco de dados."
  type        = string
  default     = "reservas"
}

variable "db_username" {
  description = "Usuário master do banco."
  type        = string
  default     = "reservas_admin"
}

variable "db_password" {
  description = "Senha do banco. Deixe null para o Terraform gerar uma aleatória (recomendado)."
  type        = string
  default     = null
  sensitive   = true
}
