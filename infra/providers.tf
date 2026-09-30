# providers.tf (ROOT)

terraform {
  # >= 1.3: o módulo security-group usa optional() nas regras de ingress
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State remoto: bucket S3 + tabela DynamoDB criados ANTES em infra/backend/.
  # Troque o bucket pelo output s3_bucket_name do backend e rode "terraform init".
  backend "s3" {
    bucket         = "technova-terraform-state-c6ca0e44"
    key            = "prova-primeiro-bimestre/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "technova-terraform-locks"
    use_lockfile   = false
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
