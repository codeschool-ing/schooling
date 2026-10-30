---
title: Uma fila que chama você
version: 1
---

A lição 18 usou o Pub/Sub, em que um publicador anuncia algo e qualquer número de assinantes reage.
**O Cloud Tasks é o outro formato: um trabalho, endereçado a um handler, entregue no ritmo que você
escolhe e repetido até dar certo.** O Pub/Sub diz "isto aconteceu"; uma tarefa diz "faça isto". Os
e-mails de confirmação de pedido da loja são tarefas: cada um precisa ser mandado uma vez, pelo
mailer, e não todos de uma vez quando uma promoção traz mil pedidos num minuto.

## O que é uma tarefa

Uma tarefa é uma requisição HTTP esperando para ser feita. Ela leva uma URL, um método, cabeçalhos
e um corpo, um horário opcional antes do qual não pode rodar, e um nome único na fila. A **fila**
guarda as tarefas e decide quando cada uma é despachada; o **handler** é qualquer endpoint HTTPS,
como um serviço do Cloud Run, que a atende. Uma resposta 2xx conclui a tarefa. Qualquer outra
coisa, ou nenhuma resposta antes do prazo de despacho, é falha, e a tarefa espera e é tentada de
novo.

Então a fila fica com três decisões que de outro modo estariam espalhadas pelo código:

- **com que velocidade**: o máximo de tarefas despachadas por segundo, e o máximo em andamento ao
  mesmo tempo;
- **com que persistência**: quantas tentativas, e quanto esperar entre elas;
- **com que identidade**: um token de identidade ou um token OAuth anexado a cada requisição, para o
  handler poder recusar tudo que não veio da fila.

## A fila, por escrito

**Crie `~/gcp/tasks` e salve isto como `main.tf`:**

```hcl
# tasks/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_cloud_tasks_queue" "emails" {
  name     = "emails"
  location = "southamerica-east1"

  rate_limits {
    max_dispatches_per_second = 5
    max_concurrent_dispatches = 10
  }

  retry_config {
    max_attempts  = 5
    min_backoff   = "10s"
    max_backoff   = "300s"
    max_doublings = 3
  }
}
```

Depois `terraform init` e o plan, filtrado nas decisões:

```
ana@laptop:~/gcp/tasks$ terraform plan -no-color | grep -E '^  #|max_dispatches|max_concurrent|max_attempts|min_backoff|max_backoff|max_doublings|^Plan'
  # google_cloud_tasks_queue.emails will be created
          + max_concurrent_dispatches = 10
          + max_dispatches_per_second = 5
          + max_attempts       = 5
          + max_backoff        = "300s"
          + max_doublings      = 3
          + min_backoff        = "10s"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Cinco por segundo, dez ao mesmo tempo, cinco tentativas.** Quem define o ritmo é o limite do
próprio provedor de e-mail: se ele aceita cinco mensagens por segundo, uma fila que manda vinte só
compra recusas. A seção 04 calcula o que o bloco de repetição quer dizer em segundos.

## Criando uma tarefa, como o Google documenta

Com uma conta, uma tarefa é criada pela aplicação, pela biblioteca cliente ou pela API, sempre que
há trabalho para enfileirar. Pela linha de comando a mesma coisa fica assim. **Este comando não foi
executado:**

```sh
gcloud tasks create-http-task --queue=emails --location=southamerica-east1 \
  --url=https://mailer-example.a.run.app/send --method=POST \
  --header=Content-Type:application/json \
  --body-content='{"order": 1042, "email": "ana@example.com"}' \
  --oidc-service-account-email=tasks@planner-dev.iam.gserviceaccount.com
```

A URL é um marcador para o endereço do mailer, que o Cloud Run atribuiria. Nada no seu laptop
despacha tarefas, então a próxima seção faz o papel da fila com o curl, e diz isso.
