output "ec2_public_ip" {
  description = "IP público da EC2."
  value       = module.ec2.public_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2."
  value       = module.ec2.instance_id
}

output "rds_endpoint" {
  description = "Endpoint (host:porta) do RDS. Só resolve para um IP privado da VPC."
  value       = module.rds.db_endpoint
}

output "api_url" {
  description = "URL base da API."
  value       = "http://${module.ec2.public_ip}:${var.api_port}"
}

output "ssh_command" {
  description = "Comando para acessar a EC2 via SSH com a chave do Learner Lab."
  value       = "ssh -i labsuser.pem ec2-user@${module.ec2.public_ip}"
}
