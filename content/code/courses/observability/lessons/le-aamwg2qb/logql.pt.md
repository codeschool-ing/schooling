---
title: LogQL: filtros, parsers, e métricas a partir de logs
version: 2
---

O LogQL, a linguagem de consulta do Loki, é um seletor de stream seguido de uma esteira de estágios
separados por `|`. O payments falha uma cobrança em vinte desde o começo da aula, então há algo a achar. O
estágio mais simples é um **filtro de linha**, `|= "texto"`, que mantém as linhas que contêm o texto,
como o `grep`:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} |= "card network"' --data-urlencode limit=2 | jq -r '.data.result[].values[][1]' | jq -c '{level, message, order_id}'
{"level":"ERROR","message":"card network unavailable","order_id":620}
{"level":"ERROR","message":"card network unavailable","order_id":640}
```

Um **parser** transforma cada linha em labels para o resto da esteira, e o JSON da aula 8 torna isso
uma palavra: `| json`. Depois dele, qualquer campo pode ser filtrado pelo nome, aqui os cartões
recusados:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} | json | approved="false"' --data-urlencode limit=2 | jq -r '.data.result[].values[][1]' | jq -c '{message, order_id, approved}'
{"message":"charge decided","order_id":619,"approved":false}
{"message":"charge decided","order_id":637,"approved":false}
```

**O filtro roda sobre campos, mas nada foi indexado para torná-lo possível**: o Loki interpretou cada
linha do payments no intervalo para achar estas. Tudo bem para alguns minutos de um serviço e lento
para um mês de todos eles. É por isso que um filtro de linha que estreita barato,
`|= "approved\": false"`, muitas vezes vai na frente do parser.

O LogQL também transforma linhas em números. O `count_over_time` conta linhas numa janela, e com
`sum by` ele lê como PromQL:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=sum by (service_name) (count_over_time({service_name=~".+"}[1m]))' | jq -r '.data.result[] | [.metric.service_name, .value[1]] | @tsv'
mailer	214
orders	239
payments	238
storefront	239
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query --data-urlencode 'query=sum by (message) (count_over_time({service_name="payments"} | json [5m]))' | jq -r '.data.result[] | [.metric.message, .value[1]] | @tsv'
card network unavailable	32
charge decided	615
```

Linhas por serviço no último minuto, e as linhas do payments nos últimos cinco por mensagem: **615
cobranças decididas e 32 falhas da rede de cartões**. Isso dá cerca de uma em vinte como configurado, com a
folga das bordas da janela. São métricas calculadas a partir de logs na hora da consulta, úteis para
uma pergunta para a qual ninguém fez uma métrica antes. Para qualquer coisa perguntada a cada quinze
segundos por um painel ou um alerta, o contador do próprio serviço das aulas 5 e 6 é muito mais
barato.
