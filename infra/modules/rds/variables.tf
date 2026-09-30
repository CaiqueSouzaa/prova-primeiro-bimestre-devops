# modules/rds/variables.tf

variable "db_name" {
  description = "Nome do database"
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
}

variable "db_password" {
  description = "Senha master do banco (alfanumérica; o RDS rejeita / @ \" e espaço)"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnets privadas (2+ AZs diferentes) para o DB Subnet Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups aplicados ao RDS"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "15"
}

variable "allocated_storage" {
  description = "Armazenamento inicial em GB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}
