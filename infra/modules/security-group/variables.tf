variable "name" {
  description = "Prefixo usado no nome e na tag Name dos security groups."
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde os security groups serão criados."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Único CIDR autorizado a acessar a porta 22 da EC2 (o seu IP público /32)."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && endswith(var.allowed_ssh_cidr, "/32")
    error_message = "allowed_ssh_cidr deve ser um único IP no formato x.x.x.x/32."
  }
}

variable "api_port" {
  description = "Porta HTTP em que a API escuta."
  type        = number
  default     = 3000
}

variable "db_port" {
  description = "Porta do PostgreSQL."
  type        = number
  default     = 5432
}
