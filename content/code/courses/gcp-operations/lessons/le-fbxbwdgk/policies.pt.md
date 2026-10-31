---
title: Uma política de alerta de métrica, condição por condição
version: 1
---

**Uma política de alerta é uma condição que o Cloud Monitoring avalia a cada minuto, e uma lista de canais que ele
notifica quando a condição fica verdadeira.** As lições 10 e 13 escreveram políticas sem canal; esta os
acrescenta, e acrescenta as decisões de que uma condição de métrica precisa e uma condição de log não precisava:
por quanto tempo o valor deve ficar acima do limite, e o que fazer quando não há dado nenhum. Nada aqui rodou
contra o Google: é o plano do Terraform, calculado localmente.

Escreva `~/gcp/tf/alerting/main.tf`:

```hcl
# tf/alerting/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_monitoring_notification_channel" "oncall" {
  display_name = "shop on-call"
  type         = "email"
  labels = {
    email_address = "oncall@shop.example.com"
  }
}

resource "google_monitoring_notification_channel" "tickets" {
  display_name = "shop tickets"
  type         = "pubsub"
  labels = {
    topic = "projects/planner-dev/topics/shop-tickets"
  }
}

resource "google_monitoring_alert_policy" "payment_retries" {
  display_name          = "payment retries high"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.tickets.id]
  severity              = "WARNING"

  conditions {
    display_name = "more than 5 retries a minute, for 10 minutes"
    condition_threshold {
      filter                  = "metric.type=\"logging.googleapis.com/user/shop/payment_retries\" resource.type=\"cloud_run_revision\""
      comparison              = "COMPARISON_GT"
      threshold_value         = 5
      duration                = "600s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "Checkout is retrying payments. Look at the payment service's latency first: lesson 10's labels say whether one provider or both."
    mime_type = "text/markdown"
  }
}
```

```
ana@laptop:~/gcp/tf/alerting$ terraform plan -input=false -no-color | grep -E "^  # |duration|evaluation_missing_data|severity|type  |Plan:"
  # google_monitoring_alert_policy.payment_retries will be created
      + severity              = "WARNING"
              + duration                = "600s"
              + evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
  # google_monitoring_notification_channel.oncall will be created
      + type                = "email"
  # google_monitoring_notification_channel.tickets will be created
      + type                = "pubsub"
Plan: 3 to add, 0 to change, 0 to destroy.
```

## A condição, linha a linha

- **O filtro** nomeia o contador baseado em log da lição 10. O tipo de métrica dele é `logging.googleapis.com/user/`
  seguido do nome da métrica: métricas de log definidas pelo usuário moram ali.
- **A agregação** soma a contagem de cada minuto (`ALIGN_SUM`) e junta as séries de todas as revisões
  (`REDUCE_SUM`), então o limite é comparado com o total do serviço, não com a parte de uma revisão.
- **`threshold_value = 5` e `duration = "600s"`**: mais de cinco tentativas por minuto, **por dez minutos**. A
  duração é o que separa um incidente de um soluço. O fundo da lição 10 às vezes chega a três num minuto; o trecho
  ruim ficou entre 11 e 18 por seis minutos. Uma condição sem duração teria disparado no primeiro minuto
  movimentado de um dia normal.
- **`evaluation_missing_data`** responde à pergunta da lição 10 sobre os minutos sem ponto. Um contador de falhas
  não tem dados exatamente quando está tudo bem, então dado ausente precisa contar como **inativo**. As outras
  escolhas, ativo ou "manter o último estado", chamariam alguém em toda noite calma ou deixariam um incidente
  aberto depois de ele acabar.

## Severidade e fechamento automático

`severity` é um rótulo no incidente, `CRITICAL`, `ERROR` ou `WARNING`, que a notificação carrega e que um canal
pode usar para rotear. `auto_close` fecha um incidente que ficou abaixo do limite por uma hora, o que mantém a
lista de incidentes abertos verdadeira sem alguém precisar arrumá-la.

## Dois canais para dois tipos de atenção

| canal | para que serve | as políticas da loja |
|---|---|---|
| `shop on-call`, e-mail e telefone | alguém precisa agir agora, a qualquer hora | uptime falhando, queima rápida do orçamento |
| `shop tickets`, um tópico do Pub/Sub | alguém precisa agir esta semana, em horário comercial | tentativas de pagamento, queima lenta do orçamento |

A política de tentativas de pagamento vai para chamados, não para quem está de plantão: tentativas custam pouco à
loja e o serviço de pagamento costuma se recuperar sozinho. A regra que a tabela codifica é a da próxima seção:
**um chamado urgente é a promessa de que alguém precisa fazer algo agora.** Tudo o que não é isso pertence a uma
fila lida de manhã.

Existem outros tipos de canal (SMS, Slack, PagerDuty, webhooks, o app móvel do Cloud). O tipo importa menos que a
divisão acima, e um canal de e-mail é o que pode ser declarado aqui sem inventar um endereço num serviço que o
curso não consegue mostrar.
