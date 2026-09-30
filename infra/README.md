# Infraestrutura AWS (Terraform) — API de Reservas

API NestJS de reservas rodando em Docker numa EC2 (subnet pública), usando um RDS
PostgreSQL 16 privado. State remoto no S3 com lock no DynamoDB. Feito para o
AWS Academy Learner Lab (`us-east-1`, sem criar IAM, key pair `vockey`).

```
infra/
├── backend/                  # bucket S3 + tabela DynamoDB do remote state (state local)
├── modules/
│   ├── vpc/                  # VPC, 2 subnets públicas + 2 privadas, IGW, route tables
│   ├── security-group/       # SG da EC2 (22 do seu IP, 3000 público) e SG do RDS (5432 só do SG da EC2)
│   ├── ec2/                  # t2.micro AL2023, LabInstanceProfile, user_data com Docker
│   │   └── templates/user_data.sh.tftpl
│   └── rds/                  # PostgreSQL 16.15, db.t3.micro, privado e cifrado
├── main.tf                   # composição dos módulos
├── variables.tf
├── outputs.tf
├── providers.tf              # provider AWS + backend "s3"
└── terraform.tfvars.example
```
```
Internet ──► IGW ──► subnet pública ──► EC2 :3000 (API em Docker)
                                         │  TLS (sslmode=require + CA do RDS)
                                         ▼
                        subnet privada ──► RDS :5432  (sem rota para a internet)
```

## Decisões que não estão óbvias no código

- **SSL obrigatório no RDS.** PostgreSQL 15+ no RDS vem com `rds.force_ssl = 1`.
  A API não configura SSL no TypeORM, então o `user_data` define
  `PGSSLMODE=require` (lido pelo driver `pg`) e `NODE_EXTRA_CA_CERTS` apontando para o
  bundle de CA do RDS: a conexão é cifrada **e** o certificado é validado.
- **Build na própria EC2.** O `user_data` clona o repositório público e roda
  `docker build` com o `Dockerfile` de `app/` (variável `app_dir`). Por isso o commit com o `Dockerfile`
  precisa estar no GitHub (`git push`) antes do `apply`. Um swap de 2 GB é criado
  porque a t2.micro (1 GB de RAM) não aguenta o `npm ci` + `nest build`.
- **Senha do banco.** Gerada por `random_password`; nunca aparece no código.
  Ela fica no state (cifrado no S3) e no `user_data` da instância, legível por quem
  tem `ec2:DescribeInstanceAttribute`. Em produção, o caminho seria o Secrets Manager.
- **Lock com DynamoDB.** No Terraform ≥ 1.11, `dynamodb_table` gera um aviso de
  depreciação (o recomendado passou a ser `use_lockfile`). Continua funcionando e
  foi mantido porque é requisito do trabalho.

## Passo a passo

### 0. Pré-requisitos

- Terraform ≥ 1.6 e AWS CLI v2.
- O commit com o `Dockerfile` enviado para o GitHub: `git push origin main`.
- A chave `labsuser.pem` (Learner Lab → **AWS Details** → **Download PEM**).
  No Linux/macOS/Git Bash: `chmod 400 labsuser.pem`.

### 1. Credenciais do Learner Lab

No Learner Lab, clique em **Start Lab**, depois **AWS Details** → **AWS CLI: Show**
e cole o conteúdo em `~/.aws/credentials` (no Windows,
`%USERPROFILE%\.aws\credentials`):

```ini
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

As credenciais expiram quando a sessão do Lab termina; repita este passo a cada sessão.

```bash
aws sts get-caller-identity           # deve mostrar assumed-role/voclabs/...
aws configure set region us-east-1
```

### 2. Bootstrap do remote state

```bash
cd infra/backend
terraform init
terraform apply
terraform output backend_config       # confira com o backend "s3" de infra/providers.tf
```

O nome do bucket é `reservas-tfstate-<ID da conta>`. Se a conta for outra,
atualize `bucket` no bloco `backend "s3"` de `infra/providers.tf`.

### 3. Infraestrutura principal

```bash
cd ..                                 # volta para infra/
cp terraform.tfvars.example terraform.tfvars
curl -s https://checkip.amazonaws.com  # use este IP em allowed_ssh_cidr com /32
# edite terraform.tfvars: owner e allowed_ssh_cidr

terraform init                        # configura o backend S3
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform output
```

O RDS leva de 5 a 10 minutos para ficar disponível. Depois que a EC2 sobe, o
`user_data` ainda leva de 5 a 10 minutos para instalar o Docker e fazer o build da imagem.
Para acompanhar:

```bash
$(terraform output -raw ssh_command)
sudo tail -f /var/log/user-data.log   # termina com "user_data finalizado"
sudo docker ps                        # STATUS deve ficar (healthy)
```

## Checklist de evidências (antes do destroy)

As evidências ficam na pasta `evidencias/` da raiz do repositório (a partir de `infra/`, `../evidencias`).

### 1. Apply e outputs

```bash
terraform plan -no-color 2>&1 | tee ../evidencias/terraform-plan.txt
terraform apply tfplan 2>&1 | tee ../evidencias/terraform-apply.txt
terraform output | tee ../evidencias/terraform-outputs.txt
```

### 2. CRUD na API gravando no RDS

```bash
API=$(terraform output -raw api_url)

curl -s $API/health
# {"status":"ok","database":"up"}

# Criar
curl -s -X POST $API/reservas -H 'Content-Type: application/json' \
  -d '{"cliente":"Maria Silva","data":"2026-10-15T19:30:00.000Z","status":"confirmada"}'

# Listar / buscar
curl -s $API/reservas
curl -s $API/reservas/1

# Atualizar
curl -s -X PUT $API/reservas/1 -H 'Content-Type: application/json' \
  -d '{"status":"cancelada"}'
curl -s $API/reservas/1

# Remover
curl -s -X DELETE $API/reservas/1
curl -s $API/reservas
```

Para provar que os dados estão no RDS (e não na EC2), crie uma reserva e consulte
direto no banco a partir da EC2, usando o mesmo arquivo de ambiente da API:

```bash
$(terraform output -raw ssh_command)
sudo docker run --rm --env-file /opt/reservas/app.env postgres:16-alpine \
  sh -c 'PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE \
         -c "SELECT * FROM tb_reservas;"'
```

Outra forma de mostrar a persistência: `sudo docker rm -f reservas-api` e, depois,
`terraform apply -replace=module.ec2.aws_instance.this`. A nova instância lista as
mesmas reservas.

### 3. O RDS não é público

```bash
ENDPOINT=$(terraform output -raw rds_endpoint | cut -d: -f1)

aws rds describe-db-instances --db-instance-identifier reservas-dev-postgres \
  --query 'DBInstances[0].{Publico:PubliclyAccessible,Cifrado:StorageEncrypted,Subnets:DBSubnetGroup.Subnets[].SubnetIdentifier}'

nslookup $ENDPOINT                    # resolve para 10.0.101.x / 10.0.102.x (IP privado)

# Tentativa a partir da sua máquina: deve dar timeout
nc -vz -w 5 $ENDPOINT 5432            # Linux/macOS/Git Bash
# Test-NetConnection $ENDPOINT -Port 5432   # PowerShell -> TcpTestSucceeded : False

# Regras dos SGs: o do RDS aceita apenas o SG da EC2
aws ec2 describe-security-groups \
  --filters Name=tag:Project,Values=reservas Name=group-name,Values='reservas-dev-*' \
  --query 'SecurityGroups[].{Nome:GroupName,Entrada:IpPermissions,Saida:IpPermissionsEgress}'
```

### 4. State no S3 e lock no DynamoDB

```bash
BUCKET=reservas-tfstate-$(aws sts get-caller-identity --query Account --output text)

aws s3api list-object-versions --bucket $BUCKET --prefix envs/dev/terraform.tfstate \
  --query 'Versions[].{Versao:VersionId,Data:LastModified,Atual:IsLatest}' --output table

aws s3api get-bucket-encryption --bucket $BUCKET
aws s3api get-public-access-block --bucket $BUCKET

aws dynamodb scan --table-name reservas-tfstate-lock
```

Para capturar o lock ativo: num terminal rode `terraform apply` e **não** responda
ao "yes". Em outro terminal, rode o `aws dynamodb scan` acima (aparece o item com
`Info` contendo quem segura o lock) e `terraform plan` (falha com
`Error acquiring the state lock`). Depois, responda `no` no primeiro terminal.

### 5. Tags

```bash
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=reservas \
  --query 'ResourceTagMappingList[].{ARN:ResourceARN,Tags:Tags}'
```

No console, abra a aba **Tags** da EC2, do RDS, da VPC e do bucket S3
(Project, Environment, ManagedBy, Owner e Name).

## Destruição (nesta ordem)

```bash
# 1. Primeiro a infraestrutura principal (o state dela vive no bucket do backend/)
cd infra
terraform destroy

# 2. Depois o backend (bucket com force_destroy = true e tabela de lock)
cd backend
terraform destroy
```

Se inverter a ordem, o `infra/` perde o state e os recursos precisam ser apagados
manualmente pelo console.

Conferência final:

```bash
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=reservas
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier'
```

A API de tags pode listar recursos já apagados por alguns minutos.
