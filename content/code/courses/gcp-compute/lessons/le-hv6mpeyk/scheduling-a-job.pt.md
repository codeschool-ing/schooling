---
title: Rodando um job num agendamento
version: 1
---

Um job não tem agendamento próprio. **Alguma outra coisa inicia cada execução, e para "toda noite
às duas" essa coisa é o Cloud Scheduler**, o cron gerenciado do Google, chamando a API do Cloud Run
em nome do job. A lição 20 trata do Cloud Scheduler por inteiro; esta seção é a única ligação de que
um job precisa.

## O que o agendamento chama

Iniciar uma execução é uma chamada de API comum: um `POST` ao método `:run` do job na API Admin do
Cloud Run. O Cloud Scheduler consegue fazer uma chamada HTTP numa expressão cron e anexar um token
OAuth de uma conta de serviço que ele pode usar, então a chamada é autorizada como qualquer outra.
Salve isto como `scheduletf/main.tf` em `~/gcp`:

```hcl
# scheduletf/main.tf
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

resource "google_service_account" "scheduler" {
  account_id   = "invoices-scheduler"
  display_name = "Starts the nightly invoice job"
}

resource "google_cloud_scheduler_job" "nightly_invoices" {
  name      = "nightly-invoices"
  region    = "southamerica-east1"
  schedule  = "0 2 * * *"
  time_zone = "America/Sao_Paulo"

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/planner-dev/locations/southamerica-east1/jobs/invoices:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }
}
```

Em `~/gcp/scheduletf`, `terraform init` e o plan:

```
ana@laptop:~/gcp/scheduletf$ terraform plan -no-color | grep -E '^  #|schedule|time_zone|uri|http_method|service_account_email|^Plan'
  # google_cloud_scheduler_job.nightly_invoices will be created
  + resource "google_cloud_scheduler_job" "nightly_invoices" {
      + schedule        = "0 2 * * *"
      + time_zone       = "America/Sao_Paulo"
          + http_method = "POST"
          + uri         = "https://run.googleapis.com/v2/projects/planner-dev/locations/southamerica-east1/jobs/invoices:run"
              + service_account_email = "invoices-scheduler@planner-dev.iam.gserviceaccount.com"
  # google_service_account.scheduler will be created
  + resource "google_service_account" "scheduler" {
      + account_id      = "invoices-scheduler"
      + email           = "invoices-scheduler@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:invoices-scheduler@planner-dev.iam.gserviceaccount.com"
Plan: 2 to add, 0 to change, 0 to destroy.
```

Três linhas levam as decisões. **`schedule` é cron padrão, cinco campos**, aqui o minuto 0 da hora
2 todo dia. **`time_zone` diz de quem são as duas horas**: sem ele o Cloud Scheduler usa UTC, e o
job rodaria às onze da noite em São Paulo, antes de acabar o dia que ele fatura. E **o token é da
conta do agendador**, que precisa de um papel para isso funcionar: permissão para rodar o job,
`roles/run.invoker` nele, concedido no mesmo arquivo numa configuração real e deixado de fora aqui
para o plan ficar curto.

## O que pode dar errado de noite

Um agendamento esconde falhas porque roda enquanto ninguém olha. Três hábitos mantêm o job de
faturas honesto, todos da documentação do Google e nenhum executado aqui:

- **um alerta numa execução que falhou**, pelas métricas de jobs do Cloud Monitoring, para uma falha
  virar uma mensagem de manhã e não a pergunta de um cliente ao meio-dia; o `gcp-operations` monta
  um;
- **um agendamento que não se sobrepõe a si mesmo**: se uma execução pode durar mais que o intervalo
  entre rodadas, duas execuções podem trabalhar nos mesmos pedidos ao mesmo tempo, e só as escritas
  idempotentes da seção anterior tornam isso inofensivo;
- **um jeito de rodar à mão**, `gcloud run jobs execute invoices`, para a manhã em que o agendamento
  falhou e as faturas continuam devidas. Um job que só pode ser iniciado pelo agendamento é um job
  que não se recupera sem esperar um dia.
