output "instance_id" {
  description = "ID da instância EC2."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "IP público da instância."
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "DNS público da instância."
  value       = aws_instance.this.public_dns
}
