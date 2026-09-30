# API de Reservas — Prova do Primeiro Bimestre (DevOps)

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

Passo a passo completo (bootstrap do remote state, `plan`/`apply`, evidências e
`destroy`) em [infra/README.md](infra/README.md).

```bash
cd infra/backend && terraform init && terraform apply   # S3 + DynamoDB (uma vez)
cd .. && cp terraform.tfvars.example terraform.tfvars   # ajuste owner e allowed_ssh_cidr
terraform init && terraform plan -out tfplan && terraform apply tfplan
terraform destroy                                       # ao final, sempre
```
