---
title: Uptime checks e um painel, declarados no Terraform
version: 1
---

**Um uptime check pergunta à API da loja de fora, de vários lugares do mundo, a cada poucos minutos, e
registra se ela respondeu.** É a única medida que não depende de o próprio código da loja relatar alguma
coisa: um processo que caiu não exporta métricas, e um uptime check percebe mesmo assim. Como o resto do
Cloud Monitoring, ele não roda no seu computador. O que roda é o plano do Terraform dele, que prova que a
configuração está bem formada e nada mais.

Crie `~/gcp/tf/monitoring` com dois arquivos. O primeiro é a configuração:

```hcl
# tf/monitoring/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_monitoring_uptime_check_config" "api" {
  display_name     = "shop-api /healthz"
  timeout          = "10s"
  period           = "300s"
  selected_regions = ["SOUTH_AMERICA", "USA", "EUROPE"]

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "planner-dev"
      host       = "shop.example.com"
    }
  }
}

resource "google_monitoring_dashboard" "api" {
  dashboard_json = file("${path.module}/dashboard.json")
}
```

O segundo é o painel, no JSON que a API do Cloud Monitoring recebe, `dashboard.json`:

```json
{
  "displayName": "shop-api",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Requests per second, by class",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"shop-api\"",
                "aggregation": {
                  "alignmentPeriod": "60s",
                  "perSeriesAligner": "ALIGN_RATE",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": ["metric.label.response_code_class"]
                }
              }
            }
          }]
        }
      },
      {
        "title": "Latency p50 and p99",
        "xyChart": {
          "dataSets": [
            {"timeSeriesQuery": {"timeSeriesFilter": {
              "filter": "metric.type=\"run.googleapis.com/request_latencies\" resource.label.service_name=\"shop-api\"",
              "aggregation": {"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_PERCENTILE_50", "crossSeriesReducer": "REDUCE_MEAN"}}}},
            {"timeSeriesQuery": {"timeSeriesFilter": {
              "filter": "metric.type=\"run.googleapis.com/request_latencies\" resource.label.service_name=\"shop-api\"",
              "aggregation": {"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_PERCENTILE_99", "crossSeriesReducer": "REDUCE_MEAN"}}}}
          ]
        }
      }
    ]
  }
}
```

```
ana@laptop:~/gcp/tf/monitoring$ terraform validate -no-color
Success! The configuration is valid.
ana@laptop:~/gcp/tf/monitoring$ terraform plan -input=false -no-color | grep -E "^  # |period|timeout|path|selected_regions|Plan:"
  # google_monitoring_dashboard.api will be created
  # google_monitoring_uptime_check_config.api will be created
      + period           = "300s"
      + selected_regions = [
      + timeout          = "10s"
          + path           = "/healthz"
Plan: 2 to add, 0 to change, 0 to destroy.
```

O primeiro gráfico do painel é a aritmética da seção anterior posta por escrito: alinhar o contador de cada
revisão a uma taxa em sessenta segundos, depois somar entre as revisões agrupando por classe de status. O
segundo lê p50 e p99 da distribuição de latência. `REDUCE_MEAN` entre revisões é um meio-termo contra o qual
a seção anterior avisou, aceito aqui porque as revisões da loja servem tráfego parecido; um serviço cujas
instâncias diferem muito desenharia uma linha por revisão.

## O uptime check, lido

- **`period = "300s"`** pergunta a cada cinco minutos de cada região. Um período mais curto percebe uma queda
  mais cedo e custa mais; cinco minutos é a escolha da loja porque o alerta dela espera duas falhas seguidas
  de qualquer forma (lição 14).
- **Três regiões**, porque uma falha vista de um lugar costuma ser a rede daquele lugar, e um alerta que
  precisa de duas de três regiões falhando raramente dispara pelo problema de outra pessoa.
- **`/healthz` responde 200 sem tocar no banco.** Isso verifica que o processo está de pé e alcançável, que é
  para o que um uptime check serve. Um health check que também consulta o banco transforma um banco lento em
  "o site caiu" visto de todas as regiões ao mesmo tempo.

## Quanto custa

Pela página de preços, lida em 30 de outubro de 2026: um uptime check é cobrado por execução, **0,30 USD por
1.000** depois do primeiro milhão de execuções por projeto por mês, e cada região conta como uma execução. O
check da loja roda 3 regiões × 12 vezes por hora × 730 horas = 26.280 vezes por mês, bem dentro do milhão. As
métricas do próprio Cloud Run do Google não custam nada para receber; métricas que um programa escreve são
cobradas por mebibyte, a 0,2580 USD por MiB depois dos primeiros 150 MiB por conta de faturamento.
