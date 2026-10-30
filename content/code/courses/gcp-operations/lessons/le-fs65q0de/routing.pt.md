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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Toda entrada que o projeto escreve entra no Log Router. Uma exclusão descarta as verificações de saúde bem-sucedidas antes de guardar. Os sinks então mandam as entradas aos destinos: _Required guarda logs de auditoria por 400 dias, o sink da loja manda as entradas do shop-api ao bucket shop mantido por 90 dias, um sink manda os erros a um tópico do Pub/Sub, e _Default fica com o resto.\"><defs><marker id=\"ah4\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">entradas</text><rect x=\"200\" y=\"95\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Log Router</text><line x1=\"152\" y1=\"130\" x2=\"198\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"20\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">_Required</text><text x=\"580\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">auditoria, 400 dias</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"43\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"75\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bucket shop</text><text x=\"580\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop-api, 90 dias</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"98\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"130\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-log-errors</text><text x=\"580\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Pub/Sub, erros</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"153\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"460\" y=\"185\" width=\"240\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">_Default</text><text x=\"580\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resto, 30 dias</text><line x1=\"352\" y1=\"130\" x2=\"458\" y2=\"208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line><rect x=\"200\" y=\"210\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">exclusão: /healthz</text><line x1=\"275\" y1=\"167\" x2=\"275\" y2=\"208\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></line></svg>", "caption": "Toda entrada é roteada; onde ela cai decide quanto custa e quanto vive.", "same": ["Log Router"]}
```

## Quanto custa

Pela página de preços, lida em 30 de outubro de 2026: as entradas são cobradas uma vez, quando são guardadas, a
**0,50 USD por GiB** depois dos primeiros 50 GiB por projeto por mês, e isso inclui 30 dias de armazenamento.
Guardá-las por mais tempo acrescenta **0,01 USD por GiB por mês** além dos 30 dias. Rotear, consultar e excluir
não custam nada.

Então as escolhas da loja têm este preço. Noventa dias em vez de trinta, para 20 GiB por mês, acrescentam 60
dias de 20 GiB, cerca de 0,40 USD por mês quando o bucket estiver cheio. A exclusão dos health checks tira um
volume pequeno e muito ruído. O erro caro é o outro: log de debug deixado ligado em produção pode escrever um
gigabyte por hora, e 720 GiB por mês, menos os 50 grátis, são 335 USD, por entradas que ninguém lê.
