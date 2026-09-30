# modules/ec2/main.tf

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile

  # user_data vazio não é enviado para a instância
  user_data = var.user_data != "" ? var.user_data : null

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
