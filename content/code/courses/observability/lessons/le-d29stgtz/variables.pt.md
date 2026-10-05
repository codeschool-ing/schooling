---
title: Variáveis: um painel para todo serviço
version: 1
---

As consultas do painel dizem `$job` onde iria o nome de um serviço, e uma **variável** no topo do
painel escolhe o que `$job` quer dizer. Os valores dela não estão escritos no arquivo; são pedidos ao
Prometheus, com `label_values(http_server_requests_total, job)`, toda vez que o painel carrega. O
Grafana transforma isso num pedido pelos valores do label, que pode ser enviado à mão pela fonte de
dados:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" localhost:3000/api/datasources/uid/prometheus/resources/api/v1/label/job/values | jq -c .data
["blackbox","mailer","node","orders","otel-collector","payments","postgres","pushgateway","rabbitmq","storefront"]
```

A lista traz todo job, e a variável oferece os que de fato têm o contador de requisições: storefront,
orders, payments. **Um painel passa então a servir todo serviço que publica as mesmas métricas**, e um
serviço acrescentado no mês que vem aparece na lista sem ninguém editar o arquivo. Esse é o argumento
mais forte para a nomenclatura consistente das aulas 5 e 6: um painel escrito uma vez para
`http_server_requests_total` funciona para todo serviço que usa esse nome, e para nenhum que inventou
o seu.

Variáveis têm um custo fácil de não ver: uma variável cuja consulta é cara roda a cada carregamento de
página, para cada pessoa olhando. `label_values` numa métrica é barato; uma variável montada sobre uma
consulta pesada de trinta dias é um painel lento antes de um único painel ter desenhado.
