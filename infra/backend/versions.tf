terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Sem bloco "backend": este diretório usa state LOCAL de propósito.
  # Ele cria o bucket e a tabela que o backend remoto de infra/ precisa,
  # então não pode depender deles (problema do "ovo e da galinha").
}
