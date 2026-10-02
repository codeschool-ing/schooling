---
title: Escrevendo a regra
version: 1
---

Os alertas novos da loja ficam em `prometheus/rules/burn.yml`, ao lado de três regras de gravação para
a taxa de queima em 1, 5 e 30 minutos. Cada uma é a expressão da aula 15 dividida pelos 0,5%
permitidos. Os dois alertas:

```
ana@obs:~/shop$ sed -n '/- alert: CheckoutBudgetBurningFast/,$p' prometheus/rules/burn.yml
      - alert: CheckoutBudgetBurningFast
        expr: checkout:burn_rate:5m > 14.4 and checkout:burn_rate:1m > 14.4
        labels:
          severity: page
          slo: checkout
        annotations:
          summary: "Checkouts are failing fast enough to spend the month's error budget in two days"
          description: "{{ $value | printf \"%.0f\" }}x the sustainable rate of failed checkouts, over 5 minutes and still now."
          runbook_url: "https://wiki.example.invalid/runbooks/checkout-failing"

      - alert: CheckoutBudgetBurningSlowly
        expr: checkout:burn_rate:30m > 3 and checkout:burn_rate:5m > 3
        labels:
          severity: ticket
          slo: checkout
        annotations:
          summary: "Checkouts are failing fast enough to spend the month's error budget in nine days"
```

Todo campo de um alerta é lido por alguém, e cada um tem um trabalho:

- **O nome diz o que está errado para os usuários**, `CheckoutBudgetBurningFast`, e não qual componente
  disparou. É a primeira coisa na tela de bloqueio de um celular.
- **`severity` decide para onde ele vai**, e é o único label que o roteamento do Alertmanager lê neste
  laboratório. `slo` diz a que objetivo ele pertence. A próxima seção o usa para que um page e um ticket
  sobre a mesma coisa não cheguem os dois.
- **`summary` é para a pessoa acordada**, então diz a consequência em palavras: *rápido o bastante para
  gastar o orçamento de erros do mês em dois dias*. Um summary que diz `burn_rate > 14.4` faz a pessoa
  traduzir às três da manhã.
- **`description` acrescenta a medição**, aqui a taxa de queima atual por `{{ $value }}`, para que o
  próprio page responda *quão grave?*
- **`runbook_url` aponta para o que fazer.** Um runbook é uma página curta: o que este alerta significa,
  as três primeiras coisas a verificar, como reverter e quem chamar. Um alerta sem runbook deixa cada
  plantonista novo redescobrir tudo isso.

Nenhum dos dois alertas tem `for:`. Um `for: 2m` atrasa todo alerta em dois minutos para filtrar
picos, e a segunda janela já faz esse trabalho sem o atraso. A seção anterior mostrou o preço de
deixá-lo de fora: quando a taxa de queima fica perto do limite, o page oscila.

O Prometheus lê o arquivo de novo, e as cinco regras carregam:

```
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name == "checkout-burn") | .rules[] | [.name, .health] | @tsv'
checkout:burn_rate:1m	unknown
checkout:burn_rate:5m	unknown
checkout:burn_rate:30m	unknown
CheckoutBudgetBurningFast	unknown
CheckoutBudgetBurningSlowly	unknown
```
