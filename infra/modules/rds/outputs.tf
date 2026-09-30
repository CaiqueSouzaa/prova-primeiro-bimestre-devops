output "db_endpoint" {
  description = "Endpoint do RDS no formato host:porta."
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Hostname do RDS (sem a porta)."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Porta do RDS."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco de dados."
  value       = aws_db_instance.this.db_name
}
