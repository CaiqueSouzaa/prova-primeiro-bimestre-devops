# AMI mais recente do Amazon Linux 2023, resolvida a cada plan (nunca um ID fixo).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Learner Lab: não criamos IAM; apenas referenciamos o instance profile existente
# (que carrega a LabRole).
data "aws_iam_instance_profile" "lab" {
  name = var.instance_profile_name
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.ec2_sg_id]
  associate_public_ip_address = true

  iam_instance_profile = data.aws_iam_instance_profile.lab.name

  # Atenção: o user_data contém a senha do banco e fica legível para quem tem
  # ec2:DescribeInstanceAttribute na conta e via IMDS dentro da instância.
  # Em produção, a senha iria para o Secrets Manager e seria lida no boot.
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    aws_region   = var.aws_region
    app_repo_url = var.app_repo_url
    app_repo_ref = var.app_repo_ref
    app_dir      = var.app_dir
    api_port     = var.api_port
    db_host      = var.db_host
    db_port      = var.db_port
    db_name      = var.db_name
    db_username  = var.db_username
    db_password  = var.db_password
  })
  # Mudanças no user_data só surtem efeito num boot novo, então recria a instância.
  user_data_replace_on_change = true

  # IMDSv2 obrigatório (mitiga SSRF). Hop limit 1 impede que os containers
  # Docker alcancem o IMDS e as credenciais da LabRole.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.name}-api-root"
    }
  }

  tags = {
    Name = "${var.name}-api"
  }
}
