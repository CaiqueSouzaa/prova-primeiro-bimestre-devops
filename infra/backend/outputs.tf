# outputs.tf

output "s3_bucket_name" {
  description = "Nome do bucket S3 para o Terraform state"
  value       = local.bucket_name
  depends_on  = [null_resource.s3_bucket]
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB usada para locking do state"
  value       = aws_dynamodb_table.locks.name
}
