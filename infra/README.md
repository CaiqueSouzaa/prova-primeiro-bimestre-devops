# Infraestrutura AWS — Terraform

Provisiona VPC, Security Groups, EC2 e RDS PostgreSQL no AWS Academy Learner Lab
para a API de Reservas TechNova.

## Estrutura

```
infra/
├── backend/               # PASSO 1 — S3 (state) + DynamoDB (lock)
│   ├── main.tf
│   ├── s3.tf
│   ├── dynamodb.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/
│   ├── vpc/               # VPC, IGW, subnets (for_each), route table
│   ├── security-group/    # SG genérico com regras dinâmicas
│   ├── ec2/               # Instância EC2 + key pair (no root)
│   └── rds/               # DB Subnet Group + RDS PostgreSQL
├── main.tf                # Composição dos módulos
├── variables.tf           # Declaração de variáveis
├── outputs.tf             # Outputs: IPs, endpoints, comandos
├── providers.tf           # Provider AWS + backend S3
└── terraform.tfvars.example
```

## Pré-requisitos

- Terraform >= 1.3 e AWS CLI instalados
- Chave SSH criada: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/technova-key -N ""`
- AWS Academy Learner Lab iniciado (aguarde o indicador 🟢)

## Passo 1 — Backend (S3 + DynamoDB)

Execute **uma única vez** por conta/sessão de Learner Lab:

```bash
cd infra/backend

# Exporte as credenciais do Learner Lab (AWS Details → AWS CLI → Show)
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"

terraform init
terraform apply   # anote o s3_bucket_name do output
```

Saída esperada:
```
s3_bucket_name      = "technova-terraform-state-XXXXXXXX"
dynamodb_table_name = "technova-terraform-locks"
```

## Passo 2 — Configurar o remote state

Edite `infra/providers.tf` e substitua o bucket pelo nome anotado no passo 1:

```hcl
backend "s3" {
  bucket         = "technova-terraform-state-XXXXXXXX"   # ← seu bucket
  key            = "prova-primeiro-bimestre/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "technova-terraform-locks"
}
```

## Passo 3 — Variáveis

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` e defina ao menos a senha do banco:

```hcl
db_password = "SenhaAlfanumerica2025"   # sem / @ " ou espaço
```

## Passo 4 — Inicializar e aplicar

```bash
cd infra

# Credenciais (repita sempre que abrir um terminal novo)
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"

terraform init                         # baixa provider e módulos
terraform validate                     # verifica sintaxe
terraform plan -out tfplan             # gera e salva o plano (evidência)
terraform apply tfplan                 # aplica — RDS leva ~8 min
terraform output                       # exibe IPs e endpoints
```

Recursos criados (~18):

| Módulo | Recurso | Detalhe |
|--------|---------|---------|
| vpc | VPC | 10.0.0.0/16, DNS habilitado |
| vpc | Internet Gateway | — |
| vpc | 4 subnets (for_each) | 2 públicas (us-east-1a/b) + 2 privadas |
| vpc | Route table pública + associações | 0.0.0.0/0 → IGW |
| security-group | SG da API | 22 e 3000 de 0.0.0.0/0 |
| security-group | SG do RDS | 5432 apenas do CIDR da VPC |
| rds | DB Subnet Group | subnets privadas em 2 AZs |
| rds | RDS PostgreSQL 15 | db.t3.micro, 20 GB, encrypted |
| ec2 | EC2 t2.micro | subnet pública, clona repo e sobe API |
| — | Key Pair | usa ~/.ssh/technova-key.pub |

## Passo 5 — Verificar a API

```bash
API_IP=$(terraform output -raw ec2_public_ip)

# Aguarde ~3 min para o user_data terminar (docker build)
curl http://$API_IP:3000/health
curl http://$API_IP:3000/reservas

# SSH na instância
ssh -i ~/.ssh/technova-key ec2-user@$API_IP

# Conectar ao RDS a partir do EC2
psql -h $(terraform output -raw db_endpoint | cut -d: -f1) \
     -U technova_admin -d reservas -p 5432
```

## Passo 6 — Destruir (sempre ao final)

```bash
# 1º destruir a infra (o state mora no bucket)
cd infra && terraform destroy

# 2º destruir o backend
cd infra/backend && terraform destroy
```

> O bucket usa `force_destroy = true`, então o destroy apaga todas as versões do state automaticamente.

## Restrições do Learner Lab

| Restrição | Como foi tratada |
|-----------|-----------------|
| Região fixa `us-east-1` | `default = "us-east-1"` em `variables.tf` |
| Sem criar IAM roles | `iam_instance_profile = "LabInstanceProfile"` (pré-existente) |
| Sem NAT Gateway | subnets privadas sem saída pública (só RDS) |
| Instâncias: t2.micro / db.t3.micro | defaults em `variables.tf` |
| Sessão expira em ~4h | sempre rode `terraform destroy` e exporte credenciais novas |

---

## ⚠️ Problema enfrentado — Bucket S3 e SCP do Learner Lab

> **Nota ao professor:** Durante a execução desta prova, encontrei um problema
> técnico fora do escopo do conteúdo ensinado, causado por uma restrição
> imposta pelo próprio ambiente do AWS Academy. Descrevo abaixo o problema e
> a solução adotada para que isso seja considerado na avaliação.

### O problema

Ao tentar criar o bucket S3 para o remote state via Terraform (`aws_s3_bucket`),
o apply falhou com o seguinte erro em **todas as tentativas**:

```
Error: getting S3 Bucket object lock configuration: AccessDenied
User is not authorized to perform: s3:GetBucketObjectLockConfiguration
with an explicit deny in a service control policy:
arn:aws:organizations::157285001713:policy/.../service_control_policy/p-c7h5ohsa
```

### Causa raiz

O AWS Academy Learner Lab possui uma **SCP (Service Control Policy)** aplicada
pela organização que nega explicitamente a permissão
`s3:GetBucketObjectLockConfiguration` para todos os usuários da conta.

O provider `hashicorp/aws` (versões 4.x **e** 5.x) faz essa chamada
automaticamente em **toda operação** que envolva o resource `aws_s3_bucket`:
criação, import, refresh e plan. Não há parâmetro de configuração no provider
que desative esse comportamento — a chamada é feita internamente pelo SDK Go,
independente do que está declarado no `.tf`.

Isso significa que **é impossível gerenciar um bucket S3 como resource
Terraform neste ambiente**, mesmo que o bucket já exista. O erro ocorre sempre.

### Tentativas realizadas antes da solução

1. Adicionar `object_lock_enabled = false` ao resource → erro persiste (a
   chamada é feita mesmo com o parâmetro explícito)
2. Adicionar `lifecycle { ignore_changes = [object_lock_enabled] }` → erro
   persiste (ocorre antes do plan, no refresh)
3. Fazer downgrade do provider para v4 → mesmo comportamento
4. Tentar `terraform import` do bucket já existente → mesmo erro no refresh

### Solução adotada

Substituí o `aws_s3_bucket` resource por um `null_resource` com
`local-exec` em PowerShell. O bucket é criado e configurado diretamente
via **AWS CLI**, que tem permissão para criar buckets sem acionar a API
bloqueada. O provider Terraform não gerencia o bucket como resource — apenas
o DynamoDB continua gerenciado pelo provider AWS normalmente.

O bucket criado possui:
- Versionamento habilitado (`put-bucket-versioning`)
- Criptografia SSE-AES256 (`put-bucket-encryption`)
- Bloqueio de acesso público (`put-public-access-block`)

Todas as funcionalidades exigidas pela prova estão implementadas — a única
diferença é o mecanismo de criação do bucket (CLI em vez de resource Terraform),
necessário exclusivamente por causa da SCP do ambiente de laboratório.

### Referência

Este comportamento do provider AWS com o Learner Lab é conhecido e documentado
em issues da comunidade Terraform:
- [GitHub hashicorp/terraform-provider-aws #28353](https://github.com/hashicorp/terraform-provider-aws/issues/28353)
- A restrição da SCP é imposta pela AWS na organização do Academy e não pode
  ser contornada pelo aluno.
