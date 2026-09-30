# main.tf — Backend: S3 + DynamoDB
#
# ATENÇÃO — Learner Lab:
# A SCP do AWS Academy bloqueia s3:GetBucketObjectLockConfiguration.
# O provider hashicorp/aws sempre chama essa API ao criar ou fazer refresh de
# aws_s3_bucket, tornando impossível gerenciar o bucket via resource Terraform.
#
# Solução: o bucket é criado e configurado via AWS CLI com null_resource +
# local-exec. O DynamoDB continua gerenciado pelo provider AWS.
#
# Compatibilidade: os provisioners usam "sh" no create e omitem o interpreter
# no destroy — assim funcionam tanto no WSL/Linux quanto no PowerShell/Windows
# (no Windows, o Terraform usa cmd.exe por padrão quando interpreter é omitido).

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ── Sufixo único para o nome do bucket ──────────────────────────────────────
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ── Nome do bucket calculado localmente ─────────────────────────────────────
locals {
  bucket_name = "technova-terraform-state-${random_id.bucket_suffix.hex}"
}

# ── Bucket criado via CLI (contorna a SCP do Learner Lab) ───────────────────
# O provider AWS não toca o bucket — evita GetBucketObjectLockConfiguration.
resource "null_resource" "s3_bucket" {
  triggers = {
    bucket_name = local.bucket_name
  }

  # create: usa sh — funciona no WSL/Linux e no Git Bash no Windows
  provisioner "local-exec" {
    interpreter = ["sh", "-c"]
    command     = <<-SH
      aws s3api create-bucket --bucket ${local.bucket_name} --region us-east-1 && \
      aws s3api put-bucket-versioning --bucket ${local.bucket_name} --versioning-configuration Status=Enabled && \
      aws s3api put-bucket-encryption --bucket ${local.bucket_name} \
        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}' && \
      aws s3api put-public-access-block --bucket ${local.bucket_name} \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true && \
      echo "Bucket ${local.bucket_name} configurado com sucesso."
    SH
  }

  # destroy: sem interpreter — Terraform usa sh no Linux e cmd no Windows
  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rb s3://${self.triggers.bucket_name} --force || true"
  }
}
