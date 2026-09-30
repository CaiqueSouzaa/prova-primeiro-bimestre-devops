# outputs.tf (ROOT)

output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "api_sg_id" {
  description = "SG da API"
  value       = module.api_sg.sg_id
}

output "rds_sg_id" {
  description = "SG do RDS"
  value       = module.rds_sg.sg_id
}

output "ec2_public_ip" {
  description = "IP público do EC2"
  value       = module.api_server.public_ip
}

output "api_url" {
  description = "URL da API de Reservas"
  value       = "http://${module.api_server.public_ip}:${var.api_port}"
}

output "db_endpoint" {
  description = "Endpoint do RDS"
  value       = module.database.db_endpoint
}

output "ssh_command" {
  description = "Comando SSH"
  value       = "ssh -i ~/.ssh/technova-key ec2-user@${module.api_server.public_ip}"
}

output "psql_command" {
  description = "Conexão ao RDS (rodar de dentro do EC2)"
  value       = "psql -h ${module.database.db_address} -U ${var.db_username} -d ${module.database.db_name} -p ${module.database.db_port}"
}
