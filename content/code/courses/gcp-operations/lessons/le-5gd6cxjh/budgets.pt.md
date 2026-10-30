---
title: Um orçamento é um alerta, não um teto
version: 1
---

**Um orçamento do Cloud Billing é um valor para um período e um conjunto de regras para avisar alguém quando o gasto
se aproxima dele. Ele não para nada.** Pertence a uma conta de faturamento, não a um projeto, e o filtro dele diz o
que conta: alguns projetos, os projetos sob uma pasta, alguns serviços, ou os recursos que trazem um rótulo. O valor é
um número que você escreve ou o gasto real do período anterior, e o período é um mês, trimestre ou ano do calendário,
cada um começando à meia-noite do horário do Pacífico, UTC-8, seja qual for o fuso da loja. Criar um orçamento exige
uma conta de faturamento, então esta etapa planeja um com o Terraform e o token falso, como na lição 5, e não cria
nada.

## Dois tipos de limite

Uma **regra de limite** (*threshold rule*) é uma parcela do valor, escrita como fração (`0.8` é 80%), com uma base:

- **`CURRENT_SPEND`**, o padrão: o dinheiro já gasto neste período passou da parcela.
- **`FORECASTED_SPEND`**: a previsão do Google para o período inteiro passou dela. Só um período do calendário aceita
  essa regra, e é ela que avisa no dia 9 em vez de no dia 30.

Uma regra de limite manda e-mail para os administradores da conta de faturamento, a menos que isso seja desligado.
**O e-mail é a parte que esta lição substitui.** Ele cai na caixa de quem administra o faturamento, que raramente é
quem consegue parar o que está gastando, e chega sem nada que um programa possa usar para agir.

## Um tópico em vez de uma caixa de entrada

A **`all_updates_rule`** manda cada atualização do orçamento para um tópico do Pub/Sub, com `schema_version` `"1.0"`,
a única aceita. O tópico recebe atualizações **em intervalos regulares, digam o que disserem os limites**: é um fluxo
do estado do orçamento, não um fluxo de alertas. As regras de limite continuam importando, porque sem nenhuma as
mensagens não trazem nada sobre limites.

Os dois orçamentos da loja, em `~/gcp/tf/budget/main.tf`. O mês foi de 623,07 USD na lição 23, então o orçamento da
loja é 700; a pasta sandbox gastou 32,94, então fica com 40:

```hcl
# tf/budget/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

variable "billing_account" {
  description = "The billing account id, XXXXXX-XXXXXX-XXXXXX"
  type        = string
}

variable "sandbox_folder" {
  description = "The sandbox folder, folders/NUMBER"
  type        = string
}

resource "google_pubsub_topic" "budget" {
  name = "budget-alerts"
}

resource "google_billing_budget" "shop" {
  billing_account = var.billing_account
  display_name    = "shop-monthly"

  budget_filter {
    projects        = ["projects/planner-prod", "projects/planner-dev"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "700"
    }
  }

  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    pubsub_topic   = google_pubsub_topic.budget.id
    schema_version = "1.0"
  }
}

resource "google_billing_budget" "sandbox" {
  billing_account = var.billing_account
  display_name    = "sandbox-monthly"

  budget_filter {
    resource_ancestors = [var.sandbox_folder]
    calendar_period    = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "40"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic   = google_pubsub_topic.budget.id
    schema_version = "1.0"
  }
}
```

A conta de faturamento e a pasta são variáveis, porque as duas são números que o Google atribui. O plano, com valores
inventados no formato deles:

```
ana@laptop:~/gcp/tf/budget$ terraform plan -input=false -no-color -var billing_account=000000-000000-000000 -var sandbox_folder=folders/100000000001 | grep -E "^  # |display_name|units|threshold_percent|spend_basis|Plan:"
  # google_billing_budget.sandbox will be created
      + display_name    = "sandbox-monthly"
              + units         = "40"
          + spend_basis       = "CURRENT_SPEND"
          + threshold_percent = 1
  # google_billing_budget.shop will be created
      + display_name    = "shop-monthly"
              + units         = "700"
          + spend_basis       = "CURRENT_SPEND"
          + threshold_percent = 0.8
          + spend_basis       = "FORECASTED_SPEND"
          + threshold_percent = 1
  # google_pubsub_topic.budget will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três recursos: o tópico e dois orçamentos. O orçamento da pasta sandbox é o que torna visível o experimento de uma
pessoa, a quarta linha do resto da lição 23. No Google Cloud, aplicar isto também exige permissão para definir a
política de IAM do tópico, porque o Billing precisa ter licença para publicar nele.

**O gasto chega a um orçamento horas depois do uso que o causou**, então um orçamento nunca é um limite rígido, mesmo
com uma ação atrás: quando a mensagem diz 100%, já se gastou mais. Esse é o motivo da regra de previsão, e o motivo de
a função da próxima etapa agir também em parcelas abaixo de 100%.
