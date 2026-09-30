terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State remoto criado pelo diretório backend/ (rode-o antes do init aqui).
  # Blocos de backend não aceitam variáveis, por isso os nomes são literais;
  # confira-os com "terraform output backend_config" no backend/.
  backend "s3" {
    bucket         = "reservas-tfstate-496269886919"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "reservas-tfstate-lock"
    encrypt        = true
  }
}

# Credenciais NÃO ficam no código: o provider lê o ~/.aws/credentials
# (ou variáveis AWS_*) com o aws_session_token temporário do Learner Lab.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}
