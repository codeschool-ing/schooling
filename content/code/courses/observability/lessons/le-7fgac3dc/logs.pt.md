---
title: Um log: um evento, com campos
version: 1
---

Todo serviço da loja escreve uma linha por evento na sua saída padrão, e cada linha é um objeto
JSON. Este é o último checkout que a vitrine registrou, deixado legível pelo `jq`:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep checkout | tail -1 | jq .
{
  "time": "2026-10-02T03:24:17.050Z",
  "level": "INFO",
  "service": "storefront",
  "logger": "storefront",
  "message": "checkout finished",
  "trace_id": "fcc594a0f3c6f9b924cc45718927651c",
  "span_id": "40246c1f5f68b907",
  "sku": "kettle",
  "order_id": 111,
  "outcome": "paid"
}
```

**Uma linha de log descreve uma coisa que aconteceu**, então pode carregar o que uma métrica não
pode: este pedido, o número 111, este produto, este resultado. É também por isso que logs custam
mais que métricas à medida que o tráfego cresce: um milhão de checkouts são um milhão destas. A
aula 8 trata do que vai numa linha e a aula 10 de quanto isso custa.

Dois campos importam mais do que parecem. `trace_id` é o id da requisição a que esta linha
pertence, o mesmo em todo serviço que essa requisição tocou, e **ele transforma logs separados numa
só história.** Buscando por ele nos logs dos outros serviços:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix payments orders | grep fcc594a0f3c6f9b924cc45718927651c | jq -c '{service, message, order_id}'
{"service":"payments","message":"charge decided","order_id":111}
{"service":"orders","message":"order stored","order_id":111}
```

O mesmo checkout, visto pelo `payments` e pelo `orders`. O `docker compose logs` só alcança os
contêineres desta máquina, porém, e um sistema de produção roda em dezenas. É por isso que o
laboratório também manda cada linha, pelo Collector, ao Loki, que guarda todas num lugar só e
aceita a mesma pergunta:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} |= "fcc594a0f3c6f9b924cc45718927651c"' | jq -r '.data.result[].values[][1]' | jq -c '{level, message, order_id}'
{"level":"INFO","message":"charge decided","order_id":111}
```

Leia estas linhas procurando o segundo e meio de lentidão, e **nada nelas o menciona.** A cobrança
foi decidida e o pedido foi guardado; cada linha é verdadeira. Um log diz o que um programa
escolheu dizer nos momentos em que escolheu dizer, e ninguém escreveu "vou esperar 1,5 segundo".
Daria para calcular o tempo pelos campos `time` de linhas em quatro serviços, se todos os relógios
concordassem no milissegundo. O sinal seguinte mede isso por você, dentro de cada serviço.
