variable "aws_region" {
  description = "Região AWS. O AWS Academy Learner Lab só permite us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome do projeto; usado como prefixo dos recursos e na tag Project."
  type        = string
  default     = "reservas"
}

variable "owner" {
  description = "Responsável pelos recursos (tag Owner)."
  type        = string
  default     = "Caique Pereira de Souza"
}
