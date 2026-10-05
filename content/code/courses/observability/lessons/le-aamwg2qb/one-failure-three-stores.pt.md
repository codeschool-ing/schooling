---
title: Um checkout falho, nos três
version: 1
---

O teste que importa é o que uma investigação faz: um checkout que falhou, achado pelo id do rastro, em
todo lugar para onde as linhas dele foram. O id do rastro da falha mais recente é tirado da própria
saída do payments, e o script espera os lotes chegarem antes de perguntar:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} |= "0232ecb24f137876488caaa13f510759"' | jq -r '.data.result[].values[][1]' | jq -c '{message, order_id}'
{"message":"card network unavailable","order_id":680}
ana@obs:~/shop$ curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{"query": {"match": {"attributes.trace_id": "0232ecb24f137876488caaa13f510759"}}}' | jq -c '.hits.hits[]._source.attributes | {message, order_id}'
{"message":"payment failed","order_id":680.0}
{"message":"card network unavailable","order_id":680.0}
{"message":"checkout failed","order_id":null}
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Accept: text/csv' 'localhost:9000/api/search/universal/relative?query=otel_attributes_trace_id:0232ecb24f137876488caaa13f510759&range=900&fields=otel_attributes_message,otel_attributes_order_id'
"timestamp","otel_attributes_message","otel_attributes_order_id"
"2026-10-02T15:42:58.000Z","payment failed","680.0"
"2026-10-02T15:42:58.000Z","card network unavailable","680.0"
"2026-10-02T15:42:58.000Z","checkout failed",
```

**A mesma falha nos três**, com uma diferença que é do seletor e não do armazenamento. A consulta ao
Loki nomeou `{service_name="payments"}` e achou a linha do payments. Ao Elasticsearch e ao Graylog foi
pedido o id do rastro nas linhas de todo serviço, e eles acharam três: o *card network unavailable* do
payments, o *payment failed* do orders e o *checkout failed* da vitrine. Tirar o label da consulta ao
Loki teria achado as três lá também, ao custo de ler todo stream.

E o Jaeger, perguntado pelo mesmo id, lista os spans daquele checkout que terminaram em erro:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/0232ecb24f137876488caaa13f510759 | jq -r '.data[0].spans[] | select(.tags[] | select(.key == "error" and .value == true)) | .operationName'
POST /charge
POST /checkout
POST
POST /orders
```

**Quatro spans falhos, da cobrança até o checkout**, a mesma cadeia que a aula 1 leu para uma
requisição lenta. Os logs dizem o que cada serviço decidiu; o rastro diz como a falha viajou. A aula
11 liga os dois dentro do Grafana, para que o id seja clicado em vez de copiado.

O preço de manter três armazenamentos se vê de fora:

```
ana@obs:~/shop$ docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}' shop-loki-1 shop-elasticsearch-1 shop-graylog-1 shop-opensearch-1 shop-mongo-1
NAME                   MEM USAGE / LIMIT
shop-loki-1            79.79MiB / 15.72GiB
shop-elasticsearch-1   1.539GiB / 15.72GiB
shop-graylog-1         719.7MiB / 15.72GiB
shop-opensearch-1      991.8MiB / 15.72GiB
shop-mongo-1           113.4MiB / 15.72GiB
ana@obs:~/shop$ rm faults/payments.json compose.override.yaml
```

**Loki, 80 MB. Elasticsearch, 1,5 GB. O Graylog e os seus dois companheiros, cerca de 1,8 GB.** São as
mesmas linhas, alguns milhares, em armazenamentos todos configurados pequenos. A maior parte da
memória das JVMs é um heap reservado de antemão, e nenhum desses números cresce linearmente com o
tráfego. O que eles mostram é a forma da troca na figura desta aula: o Loki mantém a escrita barata e
paga quando lê. Os outros dois pagam para indexar toda linha, e guardam a memória para isso. O arquivo
de falhas e o override foram removidos no fim da captura.
