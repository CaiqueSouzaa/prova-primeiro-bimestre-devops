output "state_bucket_name" {
  description = "Bucket S3 que armazena o state remoto."
  value       = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  description = "Tabela DynamoDB usada para o lock do state."
  value       = aws_dynamodb_table.lock.name
}

output "backend_config" {
  description = "Bloco de backend a usar em infra/providers.tf."
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.state.bucket}"
      key            = "envs/dev/terraform.tfstate"
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.lock.name}"
      encrypt        = true
    }
  EOT
}
