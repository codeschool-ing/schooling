---
title: Papéis personalizados, e o custo de ter um
version: 1
---

**Um papel personalizado é um conjunto de permissões que você escolhe, definido na organização ou num
projeto.** Ele existe para o caso em que nenhum papel predefinido serve: um trabalho que precisa de três
permissões de um papel e uma de outro, ou um papel predefinido com uma permissão a mais para um projeto
sensível.

O job de relatórios do planner precisa ler as mensagens publicadas no `orders` e ver que tópicos
existem, e mais nada. Nenhum papel predefinido é exatamente isso, então a equipe escreve um. Crie um
diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/roles && cd ~/gcp/roles
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

O primeiro rascunho, salvo como `roles.tf`, dá ao papel um id com hífens, do jeito que se nomeiam
projetos:

```hcl
resource "google_project_iam_custom_role" "reports_reader" {
  project     = "planner-dev"
  role_id     = "reports-reader"
  title       = "Reports reader"
  description = "Reads the orders subscription and lists topics, for the monthly reports."
  stage       = "GA"
  permissions = [
    "pubsub.subscriptions.consume",
    "pubsub.topics.list",
  ]
}
```

```
ana@laptop:~/gcp/roles$ terraform validate -no-color

Error: "role_id" ("reports-reader") doesn't match regexp "^[a-zA-Z0-9_\\.]{3,64}$"

  with google_project_iam_custom_role.reports_reader,
  on roles.tf line 3, in resource "google_project_iam_custom_role" "reports_reader":
   3:   role_id     = "reports-reader"
```

**Um id de papel não é um id de projeto.** Ele aceita letras, dígitos, sublinhados e pontos, de três a
sessenta e quatro, e nenhum hífen. A recusa veio do provider, antes de existir qualquer pedido. Com
`role_id = "reportsReader"` o plano mostra o papel que o Google guardaria:

```hcl
resource "google_project_iam_custom_role" "reports_reader" {
  project     = "planner-dev"
  role_id     = "reportsReader"
  title       = "Reports reader"
  description = "Reads the orders subscription and lists topics, for the monthly reports."
  stage       = "GA"
  permissions = [
    "pubsub.subscriptions.consume",
    "pubsub.topics.list",
  ]
}

resource "google_project_iam_member" "reports_job" {
  project = "planner-dev"
  role    = google_project_iam_custom_role.reports_reader.name
  member  = "serviceAccount:reports@planner-dev.iam.gserviceaccount.com"
}
```

```
ana@laptop:~/gcp/roles$ terraform plan -input=false -no-color | grep -E '^  # |      \+ (name|role|role_id|permissions)|^Plan:'
  # google_project_iam_custom_role.reports_reader will be created
      + name            = (known after apply)
      + permissions     = [
      + role_id         = "reportsReader"
  # google_project_iam_member.reports_job will be created
      + role    = (known after apply)
Plan: 2 to add, 0 to change, 0 to destroy.
```

O `name` do papel é `(known after apply)` porque é o Google que o escreve:
`projects/planner-dev/roles/reportsReader` para um papel num projeto,
`organizations/123456789012/roles/reportsReader` para um na organização. Esse nome completo é o que uma
concessão usa, então a concessão se refere a ele em vez de soletrá-lo.

## O custo de ter um

**Um papel personalizado não cresce.** Quando o Google acrescenta um recurso ao Pub/Sub, ele acrescenta
a permissão nova ao `roles/pubsub.subscriber`, e todo mundo que tem esse papel pode usar o recurso no
mesmo dia. O papel personalizado acima nunca a recebe; alguém precisa perceber e acrescentá-la. Para um
papel que deve ser estreito, essa é a ideia. Para um papel escrito para economizar algumas permissões,
vira um trabalho de manutenção que ninguém pediu, e o sintoma comum é um workload recusado meses depois
por uma permissão que não existia quando o papel foi escrito.

Mais três fatos que pegam as pessoas:

- **Nem toda permissão pode entrar num papel personalizado.** Cada permissão tem um nível de suporte, e
  algumas são `NOT_SUPPORTED` em papéis personalizados, ou `TESTING`, que funciona e pode mudar. O
  provider não sabe quais, então um plano que passa ainda pode ser recusado pelo Google no apply.
- **Um papel personalizado mora na organização ou num projeto, nunca numa pasta.** Um papel para todo
  projeto é definido uma vez na organização e concedido onde for preciso.
- **O id de um papel apagado não fica livre na hora.** Um papel personalizado apagado pode ser restaurado
  por sete dias, e o id dele não pode ser reaproveitado até o Google expurgá-lo, algumas semanas depois.
  Dê outro nome ao próximo.

Nenhuma das duas últimas seções rodou contra o Google: a API do IAM não tem emulador. A validação e o
plano são reais, e são do provider.
