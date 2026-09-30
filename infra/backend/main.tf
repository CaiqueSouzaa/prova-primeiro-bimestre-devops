provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "shared"
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Nomes de bucket são globais na AWS: o ID da conta garante unicidade.
  bucket_name = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}"
  table_name  = "${var.project}-tfstate-lock"
}

# ---------- S3: armazenamento do state ----------
resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  # Learner Lab: permite destruir o bucket mesmo com objetos/versões dentro.
  force_destroy = true

  tags = {
    Name = local.bucket_name
  }
}

# Versionamento: cada apply gera uma nova versão do state, permitindo recuperar
# um state corrompido ou sobrescrito por engano.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# O state guarda segredos (ex.: senha do RDS), então é cifrado em repouso.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueia qualquer forma de acesso público (ACLs e policies), mesmo por engano.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Desativa ACLs: o acesso passa a ser controlado só por IAM/bucket policy.
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Recusa qualquer requisição sem TLS, para o state nunca trafegar em texto plano.
data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json

  # A policy só pode ser aplicada depois do public access block,
  # senão a AWS pode rejeitá-la durante a criação.
  depends_on = [aws_s3_bucket_public_access_block.state]
}

# ---------- DynamoDB: lock do state ----------
# Impede que dois "terraform apply" simultâneos corrompam o state.
resource "aws_dynamodb_table" "lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = local.table_name
  }
}
