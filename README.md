# API de Reservas — Prova do Primeiro Bimestre (DevOps)

> [!WARNING]
> **Compatibilidade do ambiente**
>
> Este projeto foi desenvolvido e testado em **Linux** e **macOS**. No **Windows**, o ambiente Docker (volumes, permissões de arquivo e scripts de inicialização) pode apresentar comportamentos inesperados e **o projeto pode não funcionar corretamente**.
>
> Caso você esteja no Windows, utilize o **WSL (Windows Subsystem for Linux)** — preferencialmente com o projeto clonado dentro do filesystem nativo do Linux (`~/`), e não sob `/mnt/c/`. Isso evita erros de permissão e garante compatibilidade com Docker e Terraform.
>
> **Resumo de compatibilidade:**
> | Sistema Operacional | Suporte |
> |---|---|
> | Linux | ✅ Suportado |
> | macOS | ✅ Suportado |
> | Windows com WSL | ⚠️ Suportado (use o filesystem nativo do Linux) |
> | Windows nativo | ❌ Não suportado / pode não funcionar |

- **Aluno:** Caique Pereira de Souza
- **RA:** 6325095
- **Disciplina:** DevOps — Análise e Desenvolvimento de Sistemas (2026.2)

## Descrição

API de Reservas da TechNova: CRUD de reservas (`id`, `cliente`, `data`, `status`)
em Node.js (NestJS sobre Express) com TypeORM, persistindo em PostgreSQL. O
projeto cobre a jornada completa do bimestre: versionamento com Git, aplicação
containerizada, ambiente local com Docker Compose e infraestrutura na AWS
(AWS Academy Learner Lab) com Terraform modularizado e state remoto.

## Rotas

| Método   | Rota            | Descrição                                        |
|----------|-----------------|--------------------------------------------------|
| `POST`   | `/reservas`     | Cria uma reserva (valida os campos obrigatórios) |
| `GET`    | `/reservas`     | Lista todas as reservas                          |
| `GET`    | `/reservas/:id` | Busca uma reserva pelo `id` (404 se não existir) |
| `PUT`    | `/reservas/:id` | Atualiza uma reserva existente                   |
| `DELETE` | `/reservas/:id` | Remove uma reserva                               |
| `GET`    | `/health`       | Health check (200 só se o banco responder)       |

## Estrutura

```
.
├── app/                  # API de Reservas (NestJS): src/, package.json, Dockerfile, .dockerignore
├── docker-compose.yml    # API + PostgreSQL (ambiente local)
├── .env.example          # variáveis de ambiente (copie para .env)
├── infra/                # Terraform: módulos vpc, security-group, ec2, rds + backend/ (S3 + DynamoDB)
├── evidencias/           # saídas de docker build, docker compose ps, terraform plan
└── relatorio.md          # relatório do processo com IA
```

## Ambiente local (Docker Compose)

```bash
cp .env.example .env      # ajuste usuário/senha/banco
docker compose up -d --build
docker compose ps         # backend e postgres devem ficar (healthy)
curl http://localhost:3000/health
```

Exemplo de uso:

```bash
curl -X POST http://localhost:3000/reservas -H 'Content-Type: application/json' \
  -d '{"cliente":"Maria Silva","data":"2026-10-15T19:30:00.000Z","status":"confirmada"}'
curl http://localhost:3000/reservas
```

As migrations do TypeORM são aplicadas automaticamente na inicialização da API.

## Desenvolvimento sem Docker

```bash
cd app
npm ci
npm run start:dev         # lê o .env da raiz do repositório
```

## Infraestrutura AWS

> Documentação completa em [infra/README.md](infra/README.md).

## Relatório

O processo de desenvolvimento com IA como copiloto está documentado em [relatorio.md](relatorio.md).

### Pré-requisitos

- Terraform >= 1.3 instalado
- AWS CLI instalado
- Chave SSH criada:
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/technova-key -N ""
  ```
- AWS Academy Learner Lab iniciado e com indicador 🟢

### 1. Credenciais

A cada nova sessão do Learner Lab, exporte as credenciais temporárias
(**AWS Details → AWS CLI → Show**).

#### Windows

PowerShell:
```powershell
$env:AWS_ACCESS_KEY_ID="ASIA..."
$env:AWS_SECRET_ACCESS_KEY="..."
$env:AWS_SESSION_TOKEN="..."
$env:AWS_DEFAULT_REGION="us-east-1"
```

Prompt de Comando (cmd.exe) — sem aspas e sem espaços ao redor do `=`:
```bat
set AWS_ACCESS_KEY_ID=ASIA...
set AWS_SECRET_ACCESS_KEY=...
set AWS_SESSION_TOKEN=...
set AWS_DEFAULT_REGION=us-east-1
```

#### macOS e Linux (inclui WSL e Git Bash)

Bash ou Zsh (padrão do macOS):
```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
```

#### AWS CLI (`aws configure`)

Alternativamente, você pode configurar as credenciais de forma persistente usando o comando `aws configure`. Isso salva as credenciais no arquivo `~/.aws/credentials` (ou `%USERPROFILE%\.aws\credentials` no Windows).

> ⚠️ Como as credenciais do Learner Lab são **temporárias**, você precisará incluir também o `aws_session_token`, que o `aws configure` padrão não solicita. Use os comandos abaixo:

```bash
aws configure set aws_access_key_id "ASIA..."
aws configure set aws_secret_access_key "..."
aws configure set aws_session_token "..."
aws configure set default.region "us-east-1"
```

Ou edite diretamente o arquivo `~/.aws/credentials`:

```ini
[default]
aws_access_key_id     = ASIA...
aws_secret_access_key = ...
aws_session_token     = ...
```

E o arquivo `~/.aws/config`:

```ini
[default]
region = us-east-1
output = json
```

> As credenciais configuradas via `aws configure` persistem entre terminais, mas continuam **expirando junto com a sessão do Learner Lab** — atualize-as sempre que iniciar uma nova sessão. Nunca versione esses arquivos.

#### Conferindo

Em qualquer sistema, valide se as credenciais foram carregadas:
```bash
aws sts get-caller-identity
```

> As variáveis valem **apenas para o terminal atual** — abrir outra janela ou
> reiniciar a sessão do Learner Lab exige defini-las de novo. Não salve as
> credenciais em arquivos versionados; se preferir guardá-las num script, use
> `aws-creds.sh`, que já está no `.gitignore`.

> **Usando WSL?** Rode o Terraform dentro do filesystem nativo do Linux (`~/`)
> para evitar erros de permissão (`chmod: operation not permitted`) ao acessar
> `/mnt/c/`. Copie o projeto sem as pastas pesadas:
> ```bash
> rsync -av --exclude='node_modules' --exclude='.terraform' \
>   /mnt/c/Users/ti3/Documents/github/caique/reservas/ ~/reservas/
> cd ~/reservas
> ```

### 2. Backend (S3 + DynamoDB) — executar uma única vez

> ⚠️ O Learner Lab bloqueia `s3:GetBucketObjectLockConfiguration` via SCP,
> impossibilitando o uso do resource `aws_s3_bucket` no Terraform. O backend
> foi adaptado para criar o bucket via AWS CLI (`null_resource`). Veja a seção
> de problemas em [infra/README.md](infra/README.md) para detalhes.

```bash
cd infra/backend
terraform init
terraform apply   # confirme com "yes"
# Anote o s3_bucket_name do output, ex: technova-terraform-state-c6ca0e44
```

Após o apply, atualize `infra/providers.tf` com o nome do bucket gerado:

```hcl
backend "s3" {
  bucket = "technova-terraform-state-XXXXXXXX"   # ← substitua pelo seu
  ...
}
```

### 3. Variáveis

```bash
cd infra/
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` e defina a senha do banco (**apenas caracteres
alfanuméricos** — o RDS rejeita `/ @ " espaço`). Não adicione `default`
à variável no `variables.tf` — defina sempre pelo `terraform.tfvars`,
que está no `.gitignore` e nunca entra no repositório:

```hcl
db_password = "SuaSenhaAqui2025"
```

### 4. Inicializar e aplicar

```bash
cd infra/

terraform init        # conecta ao backend S3 e baixa módulos
terraform validate    # verifica sintaxe — deve retornar "Success"
terraform plan -out tfplan    # gera o plano (salva como evidência)
terraform apply tfplan         # aplica — o RDS leva ~8-10 min
```

> O `Still creating...` durante o apply é normal — não cancele.

### 5. Acessar a API

Ao final do apply, pegue o IP público:

```bash
terraform output ec2_public_ip
terraform output api_url
```

Aguarde **3 a 5 minutos** para o EC2 terminar o `user_data` (instala Docker,
clona o repositório e sobe o container). Então acesse:

```
http://<ec2_public_ip>:3000/health
http://<ec2_public_ip>:3000/reservas
```

Exemplo de uso:

```bash
curl -X POST http://<ec2_public_ip>:3000/reservas \
  -H 'Content-Type: application/json' \
  -d '{"cliente":"Maria Silva","data":"2026-10-15T19:30:00.000Z","status":"confirmada"}'

curl http://<ec2_public_ip>:3000/reservas
```

### 6. Destruir (sempre ao final)

```bash
# 1º — destruir a infraestrutura (VPC, EC2, RDS...)
cd infra/
terraform destroy     # confirme com "yes" (a senha pedida é ignorada no destroy)

# 2º — destruir o backend
cd infra/backend
terraform destroy     # confirme com "yes"
```

> **Por que a senha é pedida no destroy mas ignorada?**
> O Terraform carrega todas as variáveis obrigatórias para montar o grafo de
> dependências, mas no destroy ele apenas chama `DeleteDBInstance` — a AWS não
> exige a senha para deletar o banco. Qualquer valor é aceito.
