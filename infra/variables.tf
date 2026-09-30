# variables.tf (ROOT)

variable "aws_region" {
  description = "Região AWS (Learner Lab: sempre us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "technova"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Mapa de subnets (cidr, az, type): públicas e privadas em 2 AZs"
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
  default = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "public-2"  = { cidr = "10.0.2.0/24", az = "us-east-1b", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
    "private-2" = { cidr = "10.0.4.0/24", az = "us-east-1b", type = "private" }
  }
}

variable "ssh_public_key_path" {
  description = "Chave pública SSH do EC2"
  type        = string
  default     = "~/.ssh/technova-key.pub"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "api_port" {
  description = "Porta da API de Reservas"
  type        = number
  default     = 3000
}

variable "app_repo_url" {
  description = "Repositório Git clonado pelo EC2 para buildar a imagem da API (Dockerfile em app/)"
  type        = string
  default     = "https://github.com/CaiqueSouzaa/prova-primeiro-bimestre-devops.git"
}

variable "db_name" {
  description = "Nome do database"
  type        = string
  default     = "reservas"
}

variable "db_username" {
  description = "Usuário master do RDS"
  type        = string
  default     = "technova_admin"
}

variable "db_password" {
  description = "Senha master do RDS (alfanumérica; o RDS rejeita / @ \" e espaço)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe do RDS"
  type        = string
  default     = "db.t3.micro"
}
