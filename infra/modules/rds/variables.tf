variable "name" {
  description = "Prefixo usado no identificador e na tag Name dos recursos."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas (mínimo 2, em AZs diferentes) para o DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "O DB subnet group exige ao menos 2 subnets em AZs diferentes."
  }
}

variable "rds_sg_id" {
  description = "ID do security group do RDS (única regra de entrada: SG da EC2)."
  type        = string
}

variable "engine_version" {
  description = "Versão fixa do PostgreSQL."
  type        = string
  default     = "16.15"
}

variable "instance_class" {
  description = "Classe da instância do RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento em GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nome do banco de dados criado na instância."
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco."
  type        = string
}

variable "db_password" {
  description = "Senha do usuário master. Nunca escrita no código: vem de random_password ou de terraform.tfvars."
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Porta do PostgreSQL."
  type        = number
  default     = 5432
}

variable "backup_retention_period" {
  description = "Dias de retenção de backups automáticos (0 desativa, ideal para ambiente descartável)."
  type        = number
  default     = 0
}
