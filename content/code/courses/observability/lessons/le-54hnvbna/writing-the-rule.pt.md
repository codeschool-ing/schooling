---
title: Escrevendo a regra
version: 2
---

Os alertas novos da loja ficam em `prometheus/rules/burn.yml`, ao lado de três regras de gravação para
a taxa de queima em 1, 5 e 30 minutos. Cada uma é a expressão da aula 15 dividida pelos 0,5%
permitidos. O arquivo inteiro:

`~/shop/prometheus/rules/burn.yml`

```yaml
# How fast the checkout's error budget (lesson 15, 99.5%) is being spent, and
# two alerts on it. A burn rate of 1 spends the budget in exactly one window;
# 14.4 spends 2% of a 28-day budget in one hour. The lab's windows are 5m and
# 1m for the fast alert and 30m and 5m for the slow one, so that a lesson can
# watch them; production uses 1h and 5m, and 6h and 30m.
groups:
  - name: checkout-burn
    interval: 15s
    rules:
      - record: checkout:burn_rate:1m
        expr: |
          (1 - sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[1m]))
             / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))) / 0.005
      - record: checkout:burn_rate:5m
        expr: |
          (1 - sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m]))
             / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))) / 0.005
      - record: checkout:burn_rate:30m
        expr: |
          (1 - sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[30m]))
             / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[30m]))) / 0.005

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

Os dois alertas, que são o assunto desta seção:

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
