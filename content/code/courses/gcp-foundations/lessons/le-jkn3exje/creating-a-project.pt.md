---
title: Criar um projeto, e o que vem junto
version: 1
---

**Criar um projeto exige quatro decisões, e só uma delas não pode ser mudada depois.** O id é
permanente, o pai pode ser movido mas raramente é, o vínculo de faturamento pode mudar, e o nome é um
rótulo. Então o minuto gasto no id é o minuto que importa:

| | regra | exemplo |
|---|---|---|
| **id** | 6 a 30 caracteres: letras minúsculas, dígitos e hífens, começando com letra e sem terminar em hífen; único no Google Cloud, para sempre | `planner-reports` |
| **nome** | 4 a 30 caracteres: letras, dígitos, espaços, hífens, aspas e `!` | `Planner reports` |
| **pai** | uma pasta ou a organização | `folders/345678901234` |
| **conta de faturamento** | a conta que paga, lição 11 | `012345-6789AB-CDEF01` |

Um bom id diz para que serve o projeto e onde ele fica, `planner-reports`, e nada que vá deixar de ser
verdade: nem nome de pessoa, nem ano, nem a palavra `test` em algo que pode acabar em produção. O Google
sugere um id com uma cauda aleatória quando o console cria um projeto, como `planner-reports-471209`; a
cauda torna colisões improváveis e o id ilegível, e quem usa Terraform costuma escolher o seu.

## Deixar o provider conferir as regras

A equipe quer um projeto para os relatórios mensais. Crie um diretório para esta lição com o arquivo do
provider da lição 2:

```sh
mkdir -p ~/gcp/projects && cd ~/gcp/projects
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Um primeiro rascunho, salvo como `reports.tf`, quebra as duas regras de nome:

```hcl
resource "google_project" "reports" {
  name       = "Planner (reports)"
  project_id = "Planner_Reports"
  folder_id  = "345678901234"
}
```

```
ana@laptop:~/gcp/projects$ terraform validate -no-color

Error: "Planner (reports)" name must be 4 to 30 characters with lowercase and uppercase letters, numbers, hyphen, single-quote, double-quote, space, and exclamation point.

  with google_project.reports,
  on reports.tf line 2, in resource "google_project" "reports":
   2:   name       = "Planner (reports)"


Error: "Planner_Reports" project_id must be 6 to 30 with lowercase letters, digits, hyphens and start with a letter. Trailing hyphens are prohibited.

  with google_project.reports,
  on reports.tf line 3, in resource "google_project" "reports":
   3:   project_id = "Planner_Reports"
```

**As duas recusas vieram do provider, no notebook, antes de existir qualquer pedido.** Os parênteses
não são permitidos num nome, e um id não pode ter maiúsculas nem sublinhado. É o lugar mais barato para
encontrar as regras: o mesmo erro cometido no console é uma linha vermelha embaixo de um campo, e
cometido pela API é um `400` do Google. Corrigido, o arquivo fica assim:

```hcl
resource "google_project" "reports" {
  name       = "Planner reports"
  project_id = "planner-reports"
  folder_id  = "345678901234"
}

resource "google_project_service" "pubsub" {
  project = google_project.reports.project_id
  service = "pubsub.googleapis.com"
}
```

```
ana@laptop:~/gcp/projects$ terraform plan -input=false -no-color | grep -E '^  # |^Plan:|service '
  # google_project.reports will be created
  # google_project_service.pubsub will be created
      + service         = "pubsub.googleapis.com"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## Uma API é ligada por projeto

O segundo recurso é a parte que as pessoas esquecem. **Um projeto novo tem quase todas as APIs
desligadas**, e um pedido a uma que está desligada é recusado com `SERVICE_DISABLED`, quaisquer que
sejam os papéis de quem pede. Uma API é ligada, *habilitada* na palavra do Google, por projeto, com
`gcloud services enable pubsub.googleapis.com` ou com um `google_project_service` como o de cima.
Ligar uma pode levar um minuto, e algumas ligam outras junto: habilitar o Compute Engine habilita as
APIs de que ele depende.

Isso também é uma barreira. Um projeto que nunca habilitou uma API não pode ser obrigado a rodá-la por
uma credencial vazada, e uma auditoria de que APIs cada projeto tem ligadas diz muito sobre o que ele
faz. O emulador, que é uma API e mais nada, não tem noção de nada disso; o plano acima é até onde o
laboratório vai, e um `gcloud services list` contra o Google seria recusado como todo outro pedido.
