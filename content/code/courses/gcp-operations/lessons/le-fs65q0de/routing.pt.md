---
title: O Log Router, buckets, retenção e sinks
version: 1
---

**Toda entrada que um projeto escreve passa pelo Log Router, e o roteador decide onde ela é guardada.** Ele tem
uma lista de **sinks**, cada um um filtro e um destino, e manda cada entrada para cada sink cujo filtro casa.
Um projeto novo tem dois: `_Required`, que guarda logs de auditoria de atividade administrativa por 400 dias sem
cobrança e não pode ser mudado, e `_Default`, que guarda todo o resto por 30 dias. O resto desta seção
acrescenta os da loja. Nada nela rodou contra o Google: é um plano do Terraform, calculado no seu computador.

Crie `~/gcp/tf/logging/main.tf`:

```hcl
# tf/logging/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_logging_project_bucket_config" "shop" {
  project        = "planner-dev"
  location       = "southamerica-east1"
  bucket_id      = "shop"
  retention_days = 90
}

resource "google_logging_project_sink" "shop" {
  name                   = "shop-to-bucket"
  destination            = "logging.googleapis.com/projects/planner-dev/locations/southamerica-east1/buckets/shop"
  filter                 = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"shop-api\""
  unique_writer_identity = true
}

resource "google_logging_project_exclusion" "healthz" {
  name   = "drop-healthz"
  filter = "resource.type=\"cloud_run_revision\" AND httpRequest.requestUrl=\"/healthz\" AND httpRequest.status=200"
}

resource "google_pubsub_topic" "log_errors" {
  name = "shop-log-errors"
}

resource "google_logging_project_sink" "errors" {
  name                   = "shop-errors-to-pubsub"
  destination            = "pubsub.googleapis.com/projects/planner-dev/topics/shop-log-errors"
  filter                 = "resource.labels.service_name=\"shop-api\" AND severity>=ERROR"
  unique_writer_identity = true
}

resource "google_pubsub_topic_iam_member" "errors_writer" {
  topic  = google_pubsub_topic.log_errors.name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.errors.writer_identity
}
```

```
ana@laptop:~/gcp/tf/logging$ terraform plan -input=false -no-color | grep -E "^  # |retention_days|writer_identity|Plan:"
  # google_logging_project_bucket_config.shop will be created
      + retention_days  = 90
  # google_logging_project_exclusion.healthz will be created
  # google_logging_project_sink.errors will be created
      + unique_writer_identity = true
      + writer_identity        = (known after apply)
  # google_logging_project_sink.shop will be created
      + unique_writer_identity = true
      + writer_identity        = (known after apply)
  # google_pubsub_topic.log_errors will be created
  # google_pubsub_topic_iam_member.errors_writer will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

Seis recursos, e cada um é uma decisão:

- **Um bucket de log**, `shop`, em São Paulo, guardando entradas por **90 dias** em vez dos 30 do `_Default`.
  Um bucket de log é onde as entradas são guardadas e buscadas; a localização dele é onde elas vivem, o que
  importa quando um regulador pergunta.
- **Um sink para esse bucket** com tudo o que a API da loja escreve. As entradas ainda chegam ao `_Default`
  também, a não ser que o `_Default` seja instruído a excluí-las; um projeto que acrescenta buckets sem isso
  paga cada entrada duas vezes.
- **Uma exclusão** que descarta as requisições bem-sucedidas a `/healthz` antes de serem guardadas. O uptime
  check da lição 8 faz 26.280 delas por mês, e uma entrada de log para cada uma não diz nada que alguém vá ler.
  Uma entrada excluída nunca é guardada nem cobrada.
- **Um sink para o Pub/Sub** só com erros, para que algo possa reagir a eles na hora. O `writer_identity` dele é
  uma conta de serviço que o Google cria para o sink, conhecida só depois do apply, e o último recurso a deixa
  publicar no tópico. **Um sink sem essa permissão não roteia nada e só diz isso no próprio contador de
  erros.**

## Quanto custa

Pela página de preços, lida em 30 de outubro de 2026: as entradas são cobradas uma vez, quando são guardadas, a
**0,50 USD por GiB** depois dos primeiros 50 GiB por projeto por mês, e isso inclui 30 dias de armazenamento.
Guardá-las por mais tempo acrescenta **0,01 USD por GiB por mês** além dos 30 dias. Rotear, consultar e excluir
não custam nada.

Então as escolhas da loja têm este preço. Noventa dias em vez de trinta, para 20 GiB por mês, acrescentam 60
dias de 20 GiB, cerca de 0,40 USD por mês quando o bucket estiver cheio. A exclusão dos health checks tira um
volume pequeno e muito ruído. O erro caro é o outro: log de debug deixado ligado em produção pode escrever um
gigabyte por hora, e 720 GiB por mês, menos os 50 grátis, são 335 USD, por entradas que ninguém lê.
