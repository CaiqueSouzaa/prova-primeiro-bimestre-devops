variable "name" {
  description = "Prefixo usado na tag Name dos recursos (ex.: reservas-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr deve ser um CIDR IPv4 válido."
  }
}

variable "azs" {
  description = "Zonas de disponibilidade das subnets (uma subnet pública e uma privada por AZ)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    # O aws_db_subnet_group exige subnets em pelo menos 2 AZs.
    condition     = length(var.azs) >= 2
    error_message = "Informe ao menos 2 AZs (exigência do DB subnet group do RDS)."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas, na mesma ordem de azs."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas, na mesma ordem de azs."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}
