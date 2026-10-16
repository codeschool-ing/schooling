---
title: Logs Insights, e as mesmas perguntas respondidas com jq
version: 1
---

O **CloudWatch Logs Insights** é uma linguagem de consulta sobre grupos de logs: lê campos JSON pelo
nome, filtra, agrega e ordena, e é cobrado por gigabyte de logs que lê. A pergunta que a loja faz
primeiro num incidente é quais caminhos estão falhando:

```
filter status >= 500
| stats count(*) as errors by path
| sort errors desc
```

Cada linha é um comando aplicado ao resultado da anterior, unidos por `|`. `filter` mantém os eventos
que casam; `stats` agrupa e conta; `sort` ordena. Mais duas perguntas de incidente, como consultas do
Insights:

```
filter path = "/checkout"
| stats pct(ms, 50) as p50, pct(ms, 99) as p99, count(*) as requests
```

```
filter status >= 500
| stats count(*) as errors by customer
| sort errors desc
| limit 3
```

## Contra o moto

```
ana@laptop:~/aws/logs$ QUERY=$(aws logs start-query --log-group-name /shop/api --start-time $(date -d '-1 hour' +%s) --end-time $(date +%s) --query-string 'filter status >= 500 | stats count(*) as errors by path' --query queryId --output text)
ana@laptop:~/aws/logs$ aws logs get-query-results --query-id $QUERY --query '[status, length(results), results[0][0]]'
[
    "Complete",
    300,
    {
        "field": "@ptr",
        "value": "299"
    }
]
```

`Complete`, e 300 resultados: o moto devolveu todos os eventos, sem filtro nem agregação, como uma
lista de ponteiros. **Ele não avalia consultas do Insights**, então nenhuma das três acima foi
executada como escrita. As perguntas em si ainda podem ser respondidas: exporte as linhas e pergunte ao
`jq`, que lê JSON uma linha de cada vez.

```
ana@laptop:~/aws/logs$ aws logs filter-log-events --log-group-name /shop/api --query 'events[].message' --output json | jq -r '.[]' > api.jsonl
ana@laptop:~/aws/logs$ wc -l api.jsonl
300 api.jsonl
```

Quais caminhos falham, a primeira consulta:

```
ana@laptop:~/aws/logs$ jq -r 'select(.status >= 500) | .path' api.jsonl | sort | uniq -c | sort -rn
      3 /cart
      1 /checkout
```

Quão lento é o `/checkout`, a segunda, calculando a mediana e o p99 pelo posto mais próximo da lição 8:

```
ana@laptop:~/aws/logs$ jq -r 'select(.path == "/checkout") | .ms' api.jsonl | sort -n | awk '{ v[NR] = $1 } END { print "requests", NR, "p50", v[int(NR * 0.5)], "p99", v[int(NR * 0.99)] }'
requests 69 p50 51 p99 1390
```

E se um cliente está por trás dos erros, a terceira:

```
ana@laptop:~/aws/logs$ jq -r 'select(.status >= 500) | .customer' api.jsonl | sort | uniq -c | sort -rn | head -3
      1 c-1038
      1 c-1027
      1 c-1016
```

Quatro erros em 300 requisições: três em `/cart`, um em `/checkout`, cada um de um cliente diferente. O
`/checkout` atende a requisição mediana em 51 ms e o p99 em 1.390. **Nenhum cliente sozinho é o
problema**, o que descarta a explicação que as pessoas procuram primeiro. Os números são pequenos
porque a amostra é; o método é o que um incidente usa.

## O que o Insights acrescenta, e quanto custa

O `jq` sobre uma exportação funciona para algumas centenas de linhas num notebook. O Insights faz o
mesmo tipo de pergunta sobre gigabytes, em vários grupos de logs, sem movê-los, e acha sozinho os
campos de linhas JSON. Ele é cobrado por gigabyte lido, 0,009 USD em São Paulo pela lista de preços,
então uma consulta sobre um mês de logs da loja, 150 GB, custa 1,35 USD a cada vez que roda.
**Estreite primeiro o intervalo de tempo**: é o intervalo que decide quanto é lido, não o filtro.
