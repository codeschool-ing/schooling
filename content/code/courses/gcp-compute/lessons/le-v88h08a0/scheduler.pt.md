---
title: Cloud Scheduler, cron na plataforma
version: 1
---

Todo sistema acaba com trabalho que precisa acontecer no relógio: o relatório de vendas da noite, a
limpeza de hora em hora dos carrinhos abandonados. Num servidor só, isso é uma linha de cron. **O
Cloud Scheduler é a mesma linha de cron, rodada pelo Google, chamando um endpoint HTTP, um tópico
do Pub/Sub ou um handler do App Engine quando dispara.** Nenhuma máquina espera o dia inteiro para
rodar uma coisa às três da manhã.

## O job, por escrito

O relatório noturno da loja roda às três e dez, horário de São Paulo. **Crie `~/gcp/scheduler` e
salve isto como `main.tf`:**

```hcl
# scheduler/main.tf
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

resource "google_cloud_scheduler_job" "nightly" {
  name      = "nightly-report"
  region    = "southamerica-east1"
  schedule  = "10 3 * * *"
  time_zone = "America/Sao_Paulo"

  http_target {
    uri         = "https://orders.example.com/reports/nightly"
    http_method = "POST"
    oidc_token {
      service_account_email = "scheduler@planner-dev.iam.gserviceaccount.com"
    }
  }

  retry_config {
    retry_count = 2
  }
}
```

Depois `terraform init` e o plan:

```
ana@laptop:~/gcp/scheduler$ terraform plan -no-color | grep -E '^  #|schedule |time_zone|uri|http_method|retry_count|^Plan'
  # google_cloud_scheduler_job.nightly will be created
      + schedule        = "10 3 * * *"
      + time_zone       = "America/Sao_Paulo"
          + http_method = "POST"
          + uri         = "https://orders.example.com/reports/nightly"
          + retry_count          = 2
Plan: 1 to add, 0 to change, 0 to destroy.
```

**`schedule` é cron comum**, cinco campos: minuto, hora, dia do mês, mês, dia da semana, então `10
3 * * *` é 03:10 todo dia. **`time_zone` é a linha que as pessoas esquecem**, e aí o Cloud Scheduler
lê o horário em UTC, que é 00:10 em São Paulo. Com o fuso dado, o Scheduler segue as regras desse
fuso, inclusive um horário de verão que ele tenha; o Brasil não tem nenhum desde 2019, então aqui o
relatório roda às 03:10 o ano todo. A URL é um marcador para o endereço do serviço de pedidos, e o
token OIDC prova ao serviço que a chamada veio do Scheduler.

## O que custa, e os jobs gratuitos

```
ana@laptop:~/gcp$ python3 prices.py other | grep Scheduler
  Cloud Scheduler, after 3 free jobs                     0.1  per job per 31 days
```

A unidade é o job, não a execução: **dez centavos por job a cada 31 dias, por mais vezes que ele
dispare**, com três jobs gratuitos por conta de faturamento. Um job que roda a cada minuto custa o
mesmo que um que roda uma vez por mês. Isso torna o Scheduler quase de graça para a loja e faz do
custo do trabalho que ele dispara o número a vigiar.

## Scheduler e Tasks juntos

Os dois produtos se encontram no relatório noturno. O Scheduler dispara uma vez, às 03:10, e chama
um handler que cria uma tarefa por loja para a parte pesada do relatório; a fila então passa por
elas no próprio ritmo, repetindo cada uma por conta própria. **O Scheduler decide quando; a fila
decide com que velocidade e com que persistência.** Nenhum dos dois faz bem o trabalho do outro: um
agendamento não tem limite de ritmo, e uma fila não tem relógio.

Nada disso foi rodado aqui, além do plan. O handler do relatório seria escrito exatamente como o
mailer da seção 03, com as mesmas duas obrigações.
