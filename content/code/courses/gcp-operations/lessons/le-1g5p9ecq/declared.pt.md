---
title: O SLO, declarado no Cloud Monitoring
version: 1
---

**O Cloud Monitoring tem SLOs como objetos: um serviço, um SLI definido por dois filtros, uma meta e uma janela.**
Ele calcula continuamente os números da seção anterior a partir das métricas reais, desenha o orçamento como uma
linha descendo, e oferece a taxa de queima como uma série temporal que um alerta pode observar. Nada disso roda
aqui; o que roda é o plano do Terraform dos objetos, que é a definição inteira, posta por escrito.

Escreva `~/gcp/tf/slo/main.tf`:

```hcl
# tf/slo/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_monitoring_custom_service" "api" {
  service_id   = "shop-api"
  display_name = "shop-api"
}

resource "google_monitoring_slo" "availability" {
  service             = google_monitoring_custom_service.api.service_id
  slo_id              = "availability-28d"
  display_name        = "99.5% of requests succeed, 28 days"
  goal                = 0.995
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_count\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.\"service_name\"=\"shop-api\"",
      ])
      good_service_filter = join(" AND ", [
        "metric.type=\"run.googleapis.com/request_count\"",
        "resource.type=\"cloud_run_revision\"",
        "resource.label.\"service_name\"=\"shop-api\"",
        "metric.label.\"response_code_class\"!=\"5xx\"",
      ])
    }
  }
}

resource "google_monitoring_alert_policy" "fast_burn" {
  display_name = "shop-api is burning its error budget fast"
  combiner     = "AND"

  conditions {
    display_name = "burn rate above 14.4 over 1 hour"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability.id}\", \"3600s\")"
      comparison      = "COMPARISON_GT"
      threshold_value = 14.4
      duration        = "0s"
    }
  }

  conditions {
    display_name = "burn rate above 14.4 over 5 minutes"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.availability.id}\", \"300s\")"
      comparison      = "COMPARISON_GT"
      threshold_value = 14.4
      duration        = "0s"
    }
  }
}
```

```
ana@laptop:~/gcp/tf/slo$ terraform plan -input=false -no-color | grep -E "^  # |goal|rolling_period_days|threshold_value|duration|Plan:"
  # google_monitoring_alert_policy.fast_burn will be created
              + duration        = "0s"
              + threshold_value = 14.4
              + duration        = "0s"
              + threshold_value = 14.4
  # google_monitoring_custom_service.api will be created
  # google_monitoring_slo.availability will be created
      + goal                = 0.995
      + rolling_period_days = 28
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três objetos:

- **Um serviço próprio**, `shop-api`, ao qual o SLO pertence. O Cloud Monitoring também detecta serviços do Cloud
  Run sozinho e os oferece como serviços; declarar um mantém o SLO no Terraform em vez de nos cliques de alguém.
- **O SLO**: requisições boas sobre todas as requisições, ambas contadas a partir de
  `run.googleapis.com/request_count`, com bom significando "não `5xx`", como a primeira seção decidiu.
  `goal = 0.995` e 28 dias móveis.
- **O alerta**, sobre a taxa de queima, que é a próxima parte.

## Alertando sobre a taxa de queima, em duas janelas

**Um alerta sobre o próprio SLI dispara tarde demais ou vezes demais.** "Disponibilidade abaixo de 99,5% em cinco
minutos" chama alguém por um soluço de dois minutos que custou uma lasca do orçamento. "Abaixo de 99,5% em 28
dias" dispara depois de o objetivo já ter sido perdido. A taxa de queima faz a pergunta útil: no ritmo atual, em
quanto tempo o orçamento acaba?

Uma taxa de queima de **14,4** mantida por uma hora gasta 14,4 horas de orçamento naquela hora. Numa janela de 28
dias, de 672 horas, são 14,4 / 672 = 2,1% do orçamento inteiro em sessenta minutos; mantida, o orçamento dura
menos de dois dias. Isso vale acordar alguém, e o limite vem da prática de SRE do Google, onde é o chamado de
"queima rápida".

A política tem **duas condições unidas por `AND`**: a taxa de queima na última hora e nos últimos cinco minutos,
ambas acima de 14,4. A hora garante que orçamento suficiente está mesmo sendo gasto; os cinco minutos garantem
que ainda está acontecendo, para que um incidente que acabou há vinte minutos não chame ninguém pelos próximos
quarenta enquanto a média da hora desce. Uma segunda política, não escrita aqui, observa uma queima mais lenta (6
em seis horas) e abre um chamado em vez de acordar alguém.

`duration = "0s"` significa que cada condição é verdadeira assim que uma avaliação cruza o limite; as janelas
dentro de `select_slo_burn_rate` já fazem a suavização. Como está escrita, a política não nomeia canal, que a lição
14 acrescenta.
