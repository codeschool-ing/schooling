---
title: Um orçamento escrito como código
version: 2
---

Tudo até aqui acontece antes de o dinheiro ser gasto: um preço na revisão, uma tag que não pode ficar
de fora, uma busca pelo que ninguém reclamou. **Um orçamento é a conferência que roda depois**, contra o
que a conta de fato gastou, e a aula 10 do curso de nuvem montou um com o AWS CLI. O mesmo orçamento é
um recurso e, escrito ao lado do que ele vigia, ganha o que todo o resto desta configuração ganha: uma
revisão, um histórico e um `destroy` que o leva embora junto com o projeto. A Ana o escreve em
`~/shop/budget.tf`:

```hcl
resource "aws_budgets_budget" "shop" {
  name         = "shop-monthly"
  budget_type  = "COST"
  limit_amount = "300"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # only what carries the tag Project = shop
  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$shop"]
  }

  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["ana@example.com"]
  }

  notification {
    notification_type          = "FORECASTED"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["ana@example.com"]
  }
}
```

Três escolhas nele valem uma leitura devagar.

**O filtro é uma tag.** `user:Project$shop` quer dizer a tag definida pelo usuário `Project` com o valor
`shop`, então o orçamento conta só o que as tags padrão do começo desta aula marcaram. É também por
isso que aquelas tags tinham de ser impossíveis de esquecer: um recurso sem `Project` é gasto que este
orçamento nunca vê. E, como o curso de nuvem avisou, a tag só conta depois de ativada para alocação de
custos.

**O limite vem da estimativa.** O plano com preço disse 175.73 USD por mês para o que roda por hora, e
esse número é um piso, porque tráfego e requisições vêm por cima. 300 deixa espaço para o uso que
nenhum plano enxerga, sem deixar tanto que o alerta nunca dispare.

**Dois alertas, nenhum em 100% do gasto real.** Um dispara quando o gasto real passa de 80% do limite;
o outro quando a previsão da AWS para o mês passa do limite. Os dados de faturamento chegam horas
depois do uso que descrevem, então um alerta em 100% do real avisa de dinheiro que já foi; a previsão
é o aviso mais cedo que existe.

## Planejado, não aplicado

**Neste laboratório o orçamento é planejado e nunca aplicado.** O moto guarda o orçamento e depois
responde à leitura que o provider faz dos assinantes do alerta com um erro interno, que o provider
tenta de novo, então o apply não termina. Contra uma conta real, terminaria. O plano é a parte que este
laboratório consegue mostrar com verdade:

```
ana@laptop:~/shop$ terraform plan -no-color | sed -n '/Terraform will perform/,$p'
Terraform will perform the following actions:

  # aws_budgets_budget.shop will be created
  + resource "aws_budgets_budget" "shop" {
      + account_id        = (known after apply)
      + arn               = (known after apply)
      + budget_type       = "COST"
      + id                = (known after apply)
      + limit_amount      = "300"
      + limit_unit        = "USD"
      + name              = "shop-monthly"
      + name_prefix       = (known after apply)
      + tags_all          = {
          + "CostCenter"  = "cc-4410"
          + "Environment" = "prod"
          + "Owner"       = "ana"
          + "Project"     = "shop"
        }
      + time_period_end   = "2087-06-15_00:00"
      + time_period_start = (known after apply)
      + time_unit         = "MONTHLY"

      + cost_filter {
          + name   = "TagKeyValue"
          + values = [
              + "user:Project$shop",
            ]
        }

      + cost_types (known after apply)

      + notification {
          + comparison_operator        = "GREATER_THAN"
          + notification_type          = "ACTUAL"
          + subscriber_email_addresses = [
              + "ana@example.com",
            ]
          + subscriber_sns_topic_arns  = []
          + threshold                  = 80
          + threshold_type             = "PERCENTAGE"
        }
      + notification {
          + comparison_operator        = "GREATER_THAN"
          + notification_type          = "FORECASTED"
          + subscriber_email_addresses = [
              + "ana@example.com",
            ]
          + subscriber_sns_topic_arns  = []
          + threshold                  = 100
          + threshold_type             = "PERCENTAGE"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

As tags padrão chegaram também ao orçamento, em `tags_all`. `time_period_end` é o default do provider,
uma data longe o bastante para querer dizer "sem fim", e `time_period_start` fica para a AWS preencher.
O resto é o arquivo, lido de volta como a mudança que faria.

## O que um orçamento não é

Um orçamento avisa; não para nada. Quando a mensagem de 80% chega, o NAT gateway continua rodando e os
ambientes de preview continuam no ar, e alguém tem de ler a mensagem e agir, que é a rotina que o curso
de nuvem deixou escrita. A AWS também oferece o Cost Anomaly Detection, que aprende um padrão normal e
aponta uma mudança brusca em vez de uma linha fixa, e ele também é um recurso no provider,
`aws_ce_anomaly_monitor`. Fica citado aqui, não usado.

**A ordem desta aula é a ordem do custo.** Um preço na revisão segura a mudança cara antes de ela
acontecer, as tags tornam o gasto atribuível, a busca por órfãos e a data de validade pegam o que caiu
fora de toda configuração, e o orçamento é a rede embaixo de tudo, depois que o dinheiro se mexeu.
