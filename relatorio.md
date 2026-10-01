# Relatório do Processo — Prova do Primeiro Bimestre (DevOps)

**Aluno:** Caique Pereira de Souza  
**RA:** 6325095 
**Ferramenta de IA utilizada:** Claude AI Sonnet 5.5 Free (Melhoria de prompt) e Claude Code Opus 5.5 (Ajuda no projeto)

> Responda de forma dissertativa (mínimo 10 linhas por questão), com base na sua experiência real.

## Questão 1 — A Jornada Completa (Aulas 01 a 07)

_Como você conectou Git → Docker → Compose → Terraform → módulos → remote state; a ordem seguida e por quê; onde cada aula (01 a 07) aparece na solução._

Comecei pelo Git, que é o que deixa o projeto versionado e me permite mandar tudo pro GitHub. Depois veio o Docker: com o Dockerfile e o docker-compose.yml eu consigo subir a API e o PostgreSQL na minha máquina com um comando só, sem ficar configurando nada na mão. Com isso funcionando, parti pro Terraform. Quando ele sobe a EC2, o user data instala o Docker e o Git, clona o meu repositório do GitHub, builda a imagem da API e roda o container já apontando pro RDS. Na nuvem quem faz o papel do banco é o RDS, então o Compose acabou ficando só pro ambiente local.

Segui essa ordem porque uma coisa depende da outra. Sem o código no GitHub a EC2 não tem de onde puxar a aplicação, e sem o Docker não teria como rodar ela igual em todo lugar. No Terraform, antes de tudo eu criei o backend do remote state (o bucket S3 e a tabela do DynamoDB, que ficam em infra/backend), porque o projeto principal já precisa dele no terraform init. Só depois montei a infraestrutura usando os módulos vpc, security-group, rds e ec2, um usando o output do outro.

Olhando pras aulas: a 01 foi Git, GitHub e Docker; a 02 foi Docker Compose e a IA como copiloto; a 03 foi a introdução ao Terraform e à segurança com IAM; na 04 criamos a VPC, as subnets, os Security Groups e a EC2; na 05 veio o RDS na subnet privada e o remote state com S3 e DynamoDB; a 06 foi sobre Terraform Modules, que usei pra organizar tudo; e a 07 mostrou como resolver problemas grandes com IA quebrando em partes menores, que foi bem o jeito que fui montando o projeto, uma etapa de cada vez.

## Questão 2 — O Processo com IA como Copiloto

_Ferramenta usada e como; prompts principais; o que a IA gerou bem e o que precisou corrigir; comparação com fazer manualmente._

Usei duas ferramentas: o Claude Code Opus 5.5 e o Kiro.

Dificuldades? Encontrei muitas! Todo o código dentro de "app" eu escrevi sozinho, mas acabei criando o projeto com a estrutura errada. Aí pedi pro Claude Code Opus 5.5 reorganizar tudo com o prompt "Por favor, reorganize a estrutura do projeto para que fique de acordo com o arquivo 'prova-primeiro-bimestre.md'", e o resultado ficou nos commits de "3a2bb7a55e8d43478f605af42928f308153a880a" até "749447efc63b864b749e7472b9ba740d4139f153".

Depois tentei fazer o Terraform sozinho, mas travei no meio do caminho. Pedi ajuda pro Claude Code de novo, só que não deu certo, então resolvi testar o Kiro, e ele realmente me ajudou. O prompt principal foi o primeiro da conversa abaixo, onde passei o guia e o material das aulas como referência e pedi pra ele corrigir as minhas tentativas. Essa foi a nossa interação pra fazer o projeto funcionar:
```json
[
  {
    "caique": "Utilizando o arquivo 'GUIA-TERRAFORM-VPC-SG-EC2-RDS.md' e as pastas dentro de 'tfs' como referencia, implemente corretamente o Terraform conforme solicitado no arquivo 'README.md'. Tentei aplicar sozinho, porém não funcionou corretamente. Pode modificar as minhas tentativas.",
    "kiro": "Li o guia de referência (GUIA-TERRAFORM-VPC-SG-EC2-RDS.md), o README.md do projeto e todos os arquivos existentes em infra/. Identifiquei que os 4 módulos (vpc, security-group, ec2, rds) estavam com as pastas criadas mas completamente vazias — sem nenhum arquivo .tf dentro. O root module (infra/main.tf, variables.tf, outputs.tf, providers.tf) já existia com uma estrutura bem elaborada, mas sem os módulos implementados ele não poderia funcionar. Também identifiquei um problema crítico no main.tf: o módulo rds_sg usava um campo source_security_group_id nas ingress_rules, mas o tipo definido no módulo security-group só aceita cidr_blocks (list(string)) — isso causaria erro de validação. Criei um plano de 8 tarefas e executei cada uma: (1) módulo vpc com for_each para criação dinâmica de subnets via mapa de objetos, seguindo o padrão da aula-06/vpc-dynamic; (2) módulo security-group com aws_security_group_rule separado por count para regras dinâmicas de ingress e egress; (3) módulo ec2 com suporte a iam_instance_profile opcional (necessário para o LabInstanceProfile do Learner Lab) e root_block_device gp2 8GB; (4) módulo rds derivado do aula-05-rds/rds.tf com aws_db_subnet_group e aws_db_instance PostgreSQL 15; (5) corrigi o main.tf raiz trocando source_security_group_id por cidr_blocks = [var.vpc_cidr]; (6) criei terraform.tfvars.example documentando todas as variáveis; (7) criei infra/README.md com passo a passo completo de 6 passos; (8) verifiquei o .gitignore — já estava cobrindo aws-creds.sh, *.tfstate, *.tfvars (exceto .example), .terraform/ e *.tfplan, sem necessidade de alteração."
  },
  {
    "caique": "Você está trabalhando?",
    "kiro": "Sim! Estava no meio da resolução do problema do bucket S3. O erro que você tinha recebido era BucketAlreadyExists: o bucket technova-terraform-state-a30419ad ainda existia fisicamente na AWS, mas tinha sido deletado fora do Terraform (manualmente ou pela sessão anterior do Lab). O state local ainda tinha o random_id com o sufixo a30419ad registrado, então quando o Terraform tentou recriar o bucket com o mesmo nome, a AWS rejeitou com 409 Conflict. A solução foi remover o random_id.bucket_suffix do state com terraform state rm para forçar a geração de um novo sufixo aleatório na próxima execução. Após a remoção, rodei terraform state list para confirmar o que ainda estava no state (aws_dynamodb_table.locks e aws_kms_key.state — esses estavam criados com sucesso na tentativa anterior) e preparei o próximo apply."
  },
  {
    "caique": "Isso tem algo haver? 'O Lab não permite criar IAM users/groups/roles, use a role pré-existente LabRole e o instance profile LabInstanceProfile quando precisar de permissões de serviço.'",
    "kiro": "Não diretamente — são dois problemas completamente independentes. A restrição de IAM que você citou se refere à impossibilidade de criar aws_iam_role, aws_iam_user ou aws_iam_group no Learner Lab via Terraform. Isso já estava tratado corretamente: no módulo ec2 a variável iam_instance_profile tem default null, e no main.tf raiz passamos iam_instance_profile = 'LabInstanceProfile' — que é o instance profile pré-existente na conta do Lab, associado à role LabRole com permissões de serviço. O erro do bucket S3 é outro problema: uma SCP (Service Control Policy) aplicada pela AWS na organização do Academy nega explicitamente a permissão s3:GetBucketObjectLockConfiguration para todos os usuários da conta. O provider hashicorp/aws faz essa chamada automaticamente em toda operação que toca o resource aws_s3_bucket — criação, import, refresh e plan. Não é uma questão de permissão IAM da sua conta, é uma política de organização que você não pode contornar via configuração."
  },
  {
    "caique": "Você está trabalhando?",
    "kiro": "Sim! Estava reescrevendo completamente o backend para contornar a SCP do Learner Lab. Foram 4 tentativas fracassadas antes de chegar na solução: (1) adicionei object_lock_enabled = false ao resource aws_s3_bucket — o erro persiste porque a chamada é feita internamente pelo SDK Go do provider, independente do valor do parâmetro; (2) adicionei lifecycle { ignore_changes = [object_lock_enabled] } — também não resolve porque o erro ocorre na fase de refresh, antes mesmo do plan ser calculado; (3) fiz downgrade do provider para a versão 4.x com terraform init -upgrade esperando que a v4 não fizesse essa chamada — mesmo comportamento, o erro persiste em ambas as versões; (4) tentei terraform import do bucket já criado via CLI — falhou também, pois o import também executa refresh. Após essas 4 tentativas, entendi que a única solução era não usar o resource aws_s3_bucket do Terraform de forma alguma. Reescrevi o backend/main.tf substituindo o aws_s3_bucket por um null_resource com local-exec em PowerShell, que cria e configura o bucket diretamente via AWS CLI. O AWS CLI tem permissão para fazer CreateBucket e configurar versioning, SSE-AES256 e public access block — ele simplesmente não chama GetBucketObjectLockConfiguration. O DynamoDB continua gerenciado normalmente pelo provider AWS. O apply funcionou: bucket technova-terraform-state-c6ca0e44 criado com sucesso, DynamoDB technova-terraform-locks funcionando, providers.tf atualizado com o nome do bucket, terraform init e terraform validate passando no root module sem erros."
  },
  {
    "caique": "Executei o 'terraform plan -out tfplan' e defini a senha 'Caique@123'. E agora?",
    "kiro": "O próximo passo seria executar terraform apply tfplan para aplicar o plano. Porém, identifiquei um problema crítico antes de você prosseguir: a senha Caique@123 contém o caractere @ que o Amazon RDS PostgreSQL rejeita explicitamente. O RDS não aceita os seguintes caracteres especiais na senha master: / @ aspas duplas e espaço. Isso faria o apply falhar no momento de criar o aws_db_instance, bem perto do final (o RDS é o último recurso a ser criado, leva 8-10 minutos). Para evitar desperdiçar esse tempo, recomendei refazer o plan com uma senha alfanumérica como Caique2025, e só então executar o apply. Após o apply, o RDS leva de 8 a 10 minutos para ficar disponível — o Still creating... que aparece várias vezes é normal e não significa erro."
  },
  {
    "caique": "Por favor, inclua que tivemos o problema do S3 no README.md e especifique o que foi necessário para corrigir o problema, e que se possível solicitar para que isso não afete a nota da minha prova, pois tive um problema e precisei fazer isso pra poder entregar a prova",
    "kiro": "Adicionei uma seção completa no final do infra/README.md intitulada 'Problema enfrentado — Bucket S3 e SCP do Learner Lab', com um aviso destacado direcionado ao professor. A seção documenta: (1) o erro exato com a mensagem completa da SCP; (2) a causa raiz explicando que a SCP nega GetBucketObjectLockConfiguration em nível de organização AWS e que o provider Terraform chama essa API internamente no SDK Go, independente de qualquer configuração no .tf; (3) as 4 tentativas realizadas antes da solução, demonstrando que não foi uma abordagem preguiçosa mas sim um processo de investigação sistemática; (4) a solução adotada com null_resource + CLI, detalhando que todas as configurações exigidas pela prova estão presentes (versionamento, criptografia, bloqueio de acesso público); (5) uma referência ao issue #28353 do repositório oficial do provider no GitHub, comprovando que é um problema conhecido e não um erro de configuração do aluno. A seção deixa claro para o professor que o desvio foi uma necessidade técnica imposta pelo ambiente, não uma tentativa de simplificar ou burlar o requisito."
  },
  {
    "caique": "Como faço para acessar este projeto através da web? Temos o endereço ip dele?",
    "kiro": "Sim, o IP público do EC2 é exposto como output do Terraform. Rodando terraform output no diretório infra/ após o apply, aparece o ec2_public_ip e o api_url já formatado com a porta. A API fica acessível em http://<ec2_public_ip>:3000 com as rotas /health, /reservas, e as demais do CRUD. Fiz um alerta importante: o EC2 leva de 3 a 5 minutos extras após o apply terminar para o user_data concluir. O script de inicialização instala o Docker, clona o repositório do GitHub, faz o docker build da imagem (que compila o NestJS — processo pesado num t2.micro com 1GB de RAM, por isso adicionamos um swapfile de 2GB no script) e sobe o container. Se acessar antes disso, a conexão é recusada. Perguntei se o apply já tinha terminado com sucesso para confirmar que estava pronto para testar."
  },
  {
    "caique": "Certo. Obrigado pela ajuda. Por favor, remova do repositório tudo o que não for relevante para a entrega da prova",
    "kiro": "Analisei toda a estrutura do repositório listando os arquivos e lendo o conteúdo de prova-primeiro-bimestre.md e relatorio.md para entender o que era necessário. Identifiquei dois itens para remoção: a pasta tfs/ que continha todo o material das aulas (aula-01 a aula-08 com labs, slides em HTML, imagens e o guia GUIA-TERRAFORM-VPC-SG-EC2-RDS.md) — esse material foi usado como referência para implementar a solução, mas não faz parte da entrega; e o arquivo prova-primeiro-bimestre.md que era o enunciado completo da prova com critérios de avaliação, regras e dicas. Apresentei a análise ao usuário antes de deletar, confirmando o que seria removido e o que seria mantido, e aguardei a confirmação explícita. Após a confirmação, deletei os dois itens. Aproveitei para lembrar que o relatorio.md ainda estava com as 4 questões em branco e que elas valem 40% da nota total."
  },
  {
    "caique": "Sim, pode remover",
    "kiro": "Executei Remove-Item -Recurse -Force para a pasta tfs/ e Remove-Item -Force para o prova-primeiro-bimestre.md. Confirmei a remoção listando o diretório raiz do repositório. A estrutura final ficou: app/ (API NestJS com src/, Dockerfile, .dockerignore, package.json), evidencias/ (docker-build.txt e compose-ps.txt), infra/ (backend/ com null_resource para S3 e DynamoDB; modules/ com vpc, security-group, ec2 e rds; main.tf, variables.tf, outputs.tf, providers.tf, terraform.tfvars.example e README.md), .env, .env.example, .gitignore, docker-compose.yml, README.md e relatorio.md — exatamente a estrutura exigida pelo enunciado da prova."
  },
  {
    "caique": "Tenho a tarefa de coletar todas as interações que tive com IAs pra fazer o projeto, isso vale nota. Por favor, gere um '.json' com a nossa interação: Um array de objetos do tipo {\"caique\": \"...\", \"kiro\": \"...\"}.",
    "kiro": "Expliquei que não tenho acesso programático ao histórico completo da conversa pois parte das mensagens anteriores foi compactada automaticamente pelo sistema para liberar espaço de contexto. Sugeri exportar pelo Kiro IDE ou copiar o histórico manualmente. Mediante solicitação para usar o contexto disponível, gerei o arquivo interacoes-kiro.json na raiz do repositório com todas as interações que ainda estavam acessíveis no contexto da sessão, no formato de array de objetos {caique, kiro} conforme solicitado."
  },
  {
    "caique": "Por favor, inclua mais sobre as suas respostas, pois elas contam mais da história",
    "kiro": "Reescrevi o arquivo interacoes-kiro.json expandindo as respostas do Kiro em cada entrada para contar a história completa de como cada problema foi diagnosticado e resolvido: os módulos Terraform criados do zero (vpc com for_each, security-group com aws_security_group_rule, ec2 com iam_instance_profile opcional, rds derivado do material da aula-05); a batalha com a SCP do Learner Lab que bloqueava s3:GetBucketObjectLockConfiguration em 4 tentativas diferentes até chegar na solução com null_resource + PowerShell CLI; a correção da senha do RDS que continha @ antes do apply; a documentação do problema no README para o professor; e a limpeza final do repositório removendo o material de referência das aulas."
  },
  {
    "caique": "Executei o comando 'terraform destroy' e digitei a senha 'sdfsdf', a qual eu não havia definido no 'terraform apply tfplan', porém ele seguiu corretamente. Por que me foi solicitado a senha e por que uma senha incorreta foi aceita?",
    "kiro": "Expliquei que são duas perguntas com respostas independentes. A senha foi solicitada porque a variável db_password está declarada em variables.tf sem default — o Terraform sempre exige o valor de variáveis obrigatórias ao carregar a configuração, e ele precisa carregar tudo para montar o grafo de dependências e saber o que destruir. Já a senha incorreta foi aceita porque no destroy o Terraform não cria nem modifica recursos — ele apenas os deleta. Para deletar um RDS, a AWS recebe a chamada DeleteDBInstance que não exige nem verifica a senha master do banco. A senha só é relevante no apply quando o banco está sendo criado via CreateDBInstance. Qualquer string teria funcionado no destroy porque o valor é carregado na memória pelo Terraform mas nunca enviado para a AWS nesse fluxo."
  },
  {
    "caique": "Por favor, inclua no README.md todo o processo certinho pra executar a aplicação usando o terraform",
    "kiro": "Reescrevi a seção de Infraestrutura AWS do README.md raiz, substituindo o bloco de 4 linhas que existia por um passo a passo completo dividido em 6 etapas numeradas: (1) Credenciais — como exportar as variáveis de ambiente no PowerShell a cada nova sessão do Learner Lab; (2) Backend — terraform init e apply no diretório infra/backend, com nota sobre o problema da SCP e o link para a documentação detalhada; (3) Variáveis — como copiar o terraform.tfvars.example e o aviso sobre caracteres proibidos na senha do RDS; (4) Init, validate, plan e apply — sequência completa com nota de que o Still creating... é normal e não deve ser cancelado; (5) Acessar a API — como pegar o IP com terraform output, quanto tempo aguardar para o user_data terminar e exemplos de curl para /health e /reservas; (6) Destroy — ordem correta (infra primeiro, backend depois) e a explicação de por que a senha é pedida mas ignorada no destroy, aproveitando a dúvida que o usuário havia levantado."
  },
  {
    "caique": "Tentei executar no wsl e deu erro 'chmod .terraform/providers/.../LICENSE.txt: operation not permitted', porém no powershell funcionou corretamente",
    "kiro": "Expliquei que o erro não tem nada a ver com o código Terraform — é uma limitação do WSL ao acessar arquivos em /mnt/c/ (sistema de arquivos NTFS do Windows). O kernel Linux não consegue executar chmod em arquivos montados via WSL porque o NTFS não suporta permissões POSIX da mesma forma. O Terraform tenta ajustar permissões nos arquivos do provider após o download, o que falha nesse contexto. Apresentei duas opções: (1) continuar usando o PowerShell, que já funciona corretamente; (2) copiar o projeto para dentro do filesystem nativo do WSL (~/) onde o chmod funciona normalmente. Recomendei o PowerShell por ser mais simples para esta entrega."
  },
  {
    "caique": "E tem como copiar sem o 'node_modules'? Ela é muito pesada",
    "kiro": "Sim, o rsync que já vem instalado no WSL resolve isso com a flag --exclude. Forneci o comando: rsync -av --exclude='node_modules' --exclude='.terraform' /mnt/c/Users/ti3/Documents/github/caique/reservas/ ~/reservas/ — explicando que --exclude='node_modules' pula as dependências do Node e --exclude='.terraform' pula os providers do Terraform que serão baixados novamente pelo terraform init dentro do WSL."
  },
  {
    "caique": "Está certo? 'variable \"db_password\" { description = \"...\" type = string sensitive = true default = \"Caique123\" }'",
    "kiro": "Funciona tecnicamente, mas tem dois problemas sérios. Primeiro, um risco de segurança: o variables.tf é versionado no Git e qualquer pessoa que clonar o repositório verá a senha em texto plano. O sensitive = true só evita que o valor apareça nos logs do Terraform — não protege o código fonte. Segundo, pode reprovar na prova: o enunciado exige .gitignore adequado e não versionar senhas, e um professor atento vai identificar a senha exposta no variables.tf. A prática correta é manter a variável sem default no variables.tf e definir a senha no terraform.tfvars que está coberto pelo .gitignore (*.tfvars). Assim o Terraform lê automaticamente do arquivo sem pedir no terminal e a senha nunca entra no Git."
  },
  {
    "caique": "Por favor, atualize o 'interacoes-kiro.json'",
    "kiro": "Adicionei as 4 interações mais recentes ao arquivo interacoes-kiro.json: a explicação sobre o terraform destroy aceitar qualquer senha; a reescrita completa da seção de infraestrutura no README.md raiz com o passo a passo detalhado em 6 etapas; a explicação do erro de chmod no WSL ao acessar /mnt/c/ e as duas opções de solução; o comando rsync com --exclude para copiar o projeto sem node_modules; e o alerta sobre o risco de versionar a senha do RDS com default no variables.tf."
  }
]

```

O que a IA fez bem: montou os módulos vpc, security-group, ec2 e rds seguindo o material das aulas, achou o erro do source_security_group_id no meu main.tf e me avisou de coisas que eu tinha deixado passar, como o @ na senha do RDS e a senha com default no variables.tf, que ia acabar indo pro Git. O que precisou corrigir: o backend com aws_s3_bucket não funcionava no Learner Lab por causa da SCP, e foram 4 tentativas até trocar por um null_resource com AWS CLI.

Comparando com fazer na mão, sozinho eu não tinha conseguido fazer o Terraform funcionar, e com a IA foi bem mais rápido. Mas não dá pra só aceitar o que ela gera: em vários momentos tive que perguntar, testar e conferir antes de seguir.

## Questão 3 — Infraestrutura, Segurança e o Learner Lab

_Arquitetura provisionada; por que o RDS fica na subnet privada e a EC2 na pública; uso do `LabRole`/`LabInstanceProfile`; ajustes exigidos pelo Learner Lab._

A arquitetura tem uma VPC com duas subnets públicas e duas privadas, em duas AZs. As públicas saem pra internet pelo Internet Gateway e as privadas não têm saída. A EC2 com a API fica numa subnet pública e o RDS PostgreSQL fica nas privadas.

O RDS fica na subnet privada porque ele não deve ser exposto pra internet aberta, onde ficaria acessível pra todo mundo. Ele só pode ser acessado de dentro da VPC: está com publicly_accessible = false e o Security Group dele só libera a porta 5432 pro CIDR da VPC. É assim que a EC2, mesmo estando na subnet pública, consegue conversar com o banco.

A EC2 está na subnet pública porque é nela que está a API, e a API precisa ficar exposta pro mundo, e somente ela, pra que as pessoas ou outros serviços de fora possam acessar. O Security Group dela libera só a porta 3000 da API e a 22 do SSH.

Como o Learner Lab não deixa criar IAM roles, não criei nenhuma no Terraform: na EC2 só passei iam_instance_profile = "LabInstanceProfile", que já existe na conta e usa a LabRole. Também tive que usar a região us-east-1, instâncias t2.micro e db.t3.micro, ficar sem NAT Gateway, exportar as credenciais de novo a cada sessão e criar o bucket do remote state com null_resource, por causa da SCP que bloqueia o s3:GetBucketObjectLockConfiguration.

## Questão 4 — Validação e Responsabilidade

_Checklist aplicado antes do `terraform apply`; como validou a infraestrutura; riscos de aceitar código da IA sem revisão; como a evolução Git → Docker → Terraform → Modules preparou você._

O "terraform plan" e o "terraform apply" me deram muita dor de cabeça, porque os arquivos .tf gerados pelo Claude quase sempre vinham errados ou com coisas a mais do que eu tinha pedido, e eu sempre precisava corrigir.

Por isso, antes de rodar o apply eu passava por um checklist: exportar as credenciais do Learner Lab de novo, ver se o backend (S3 e DynamoDB) já estava criado, conferir se a senha do RDS estava no terraform.tfvars e não com default no variables.tf, ver se ela não tinha caracteres que o RDS não aceita (como o @), rodar o terraform validate e depois o terraform plan -out tfplan, lendo o que ia ser criado antes de aplicar.

Pra validar a infraestrutura, depois do apply eu pegava o IP com o terraform output, esperava uns minutos o user data terminar e testava a API no navegador e com curl nas rotas /health e /reservas. Como o /health só responde 200 se o banco responder, ele já mostra que a EC2 está conseguindo falar com o RDS.

O risco de aceitar o código da IA sem revisar é subir algo que não funciona ou que fica inseguro. No meu caso aconteceu de verdade: o main.tf tinha um campo que o módulo não aceitava, a senha com @ ia fazer o RDS falhar no final do apply, e a senha com default no variables.tf ia acabar indo pro Git.

O Git -> Docker -> Terraform -> Modules me mostrou que é extremamente fácil subir um sistema pra nuvem, mas que configurar tudo certo não é. Cada etapa preparou a próxima: com o código no Git e a API já rodando no Docker, a EC2 só precisava clonar e subir o container, e com os módulos ficou mais fácil achar e corrigir cada parte separada.
