---
title: Alertas sobre uma única linha
version: 1
---

**Algumas linhas importam na primeira vez que aparecem, e contá-las por minuto é a ferramenta errada.** A lição
4 terminou com o break-glass: um deploy admitido sem assinatura, registrado no log de auditoria e revisado "de
manhã". A revisão só acontece se alguém for avisado. Um **alerta baseado em log** é uma política cuja condição é
um filtro de log: uma entrada que casa abre um incidente e manda uma notificação, sem métrica no meio. Nada
disso roda aqui; faz parte do mesmo plano do Terraform.

Acrescente isto em `~/gcp/tf/logmetrics/alerts.tf`:

```hcl
# tf/logmetrics/alerts.tf
resource "google_monitoring_alert_policy" "break_glass" {
  display_name = "Binary Authorization break-glass used"
  combiner     = "OR"

  conditions {
    display_name = "a break-glass deployment was admitted"
    condition_matched_log {
      filter = "resource.type=\"k8s_cluster\" AND protoPayload.request.metadata.annotations.\"alpha.image-policy.k8s.io/break-glass\"=\"true\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
    auto_close = "1800s"
  }

  documentation {
    content   = "Somebody deployed an unsigned image with break-glass. Find who in the audit log, and why, before the end of the day."
    mime_type = "text/markdown"
  }
}
```

```
ana@laptop:~/gcp/tf/logmetrics$ terraform plan -input=false -no-color | grep -E "^  # |metric_kind|value_type|period|Plan:"
  # google_logging_metric.order_value will be created
          + metric_kind = "DELTA"
          + value_type  = "DISTRIBUTION"
  # google_logging_metric.payment_retries will be created
          + metric_kind = "DELTA"
          + value_type  = "INT64"
              + value_type  = "STRING"
  # google_monitoring_alert_policy.break_glass will be created
              + period = "300s"
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três recursos: as duas métricas da seção anterior e esta política. Lendo a política:

- **`condition_matched_log`** é a condição inteira: um filtro no log de auditoria do GKE para uma requisição
  com a anotação de break-glass, como a documentação do Google o escreve. Não há limite nem janela; uma entrada
  basta.
- **`notification_rate_limit`** manda no máximo uma notificação a cada cinco minutos por esta política. Um
  alerta baseado em log dispara uma vez por entrada que casa, e uma pessoa tentando dez vezes um deploy com
  break-glass mandaria dez mensagens. Um alerta baseado em log precisa ter este bloco; o Cloud Monitoring recusa
  um sem ele.
- **`auto_close`** fecha o incidente depois de meia hora sem novo casamento, já que uma linha única não
  "se recupera" como uma métrica.
- **`documentation`** é o texto que chega com a notificação. Diz o que aconteceu e o que fazer em seguida, numa
  frase, porque quem o lê pode estar lendo num celular à noite.

A política não nomeia nenhum canal de notificação, então, como está escrita, abriria incidentes de que ninguém
fica sabendo. A lição 14 acrescenta os canais, e é sobre quais alertas merecem acordar alguém.

## Contador ou alerta de log

| a pergunta | a ferramenta |
|---|---|
| isto está acontecendo mais que o normal? | um contador, e um alerta sobre a taxa dele (lição 14) |
| isto aconteceu alguma vez? | um alerta baseado em log |
| como esses valores se espalham? | uma distribuição |

Um alerta baseado em log sobre "payment retried" notificaria alguém a cada tentativa do fundo da primeira
seção: vinte e uma delas nos vinte e quatro minutos calmos daquele log, e nenhuma delas um problema. Essa
pergunta é a da primeira linha, e o contador a responde.
