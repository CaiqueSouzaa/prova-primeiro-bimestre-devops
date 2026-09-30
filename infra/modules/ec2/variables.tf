variable "name" {
  description = "Prefixo usado na tag Name dos recursos."
  type        = string
}

variable "aws_region" {
  description = "Região AWS (usada para baixar o bundle de CA do RDS correspondente)."
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2."
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "ID da subnet pública onde a instância será criada."
  type        = string
}

variable "ec2_sg_id" {
  description = "ID do security group da EC2."
  type        = string
}

variable "key_name" {
  description = "Nome do key pair existente para acesso SSH (no Learner Lab: vockey)."
  type        = string
}

variable "instance_profile_name" {
  description = "Instance profile já existente no Learner Lab (não é criado pelo Terraform)."
  type        = string
  default     = "LabInstanceProfile"
}

variable "root_volume_size" {
  description = "Tamanho do volume raiz em GB (espaço para imagens e build Docker)."
  type        = number
  default     = 20
}

variable "app_repo_url" {
  description = "URL HTTPS do repositório Git público do projeto."
  type        = string
}

variable "app_repo_ref" {
  description = "Branch ou tag do repositório a ser implantada."
  type        = string
  default     = "main"
}

variable "app_dir" {
  description = "Diretório, relativo à raiz do repositório, que contém o Dockerfile da API."
  type        = string
  default     = "app"
}

variable "api_port" {
  description = "Porta HTTP da API."
  type        = number
  default     = 3000
}

variable "db_host" {
  description = "Hostname do RDS."
  type        = string
}

variable "db_port" {
  description = "Porta do RDS."
  type        = number
}

variable "db_name" {
  description = "Nome do banco de dados."
  type        = string
}

variable "db_username" {
  description = "Usuário do banco usado pela API."
  type        = string
}

variable "db_password" {
  description = "Senha do banco usada pela API."
  type        = string
  sensitive   = true
}
