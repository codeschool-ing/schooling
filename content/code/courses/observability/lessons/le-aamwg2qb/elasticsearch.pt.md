---
title: Elasticsearch: indexar tudo na entrada
version: 1
---

O Elasticsearch toma a decisão oposta. **Todo campo de toda linha é indexado quando chega**, num
*índice invertido*: para cada palavra e cada valor, a lista dos documentos que o contêm. O exporter
do Collector escreve as linhas num data stream nomeado pelas convenções do OpenTelemetry:

```
ana@obs:~/shop$ curl -s 'localhost:9200/_cat/indices/logs-*?h=index,health,docs.count,store.size'
.ds-logs-generic.otel-default-2026.10.02-000001 yellow 2169 806.7kb
```

2169 documentos e 807 KB, índice incluído. Para indexar um campo, o Elasticsearch precisa decidir de
que tipo ele é, e decide pelos valores que recebe, um **mapeamento** (mapping):

```
ana@obs:~/shop$ curl -s 'localhost:9200/logs-generic.otel-default/_mapping/field/attributes.order_id,attributes.message' | jq -c '.[].mappings | map_values(.mapping | to_entries[0].value.type)'
{"attributes.order_id":"float","attributes.message":"match_only_text"}
```

`order_id` virou `float`, porque o Collector repassa todo número JSON como double, e `message` virou
texto, quebrado em palavras para busca. As duas são decisões com consequências: um id de pedido float
compara e ordena como número mas imprime como `600.0`, e **um campo de texto é buscado pelas suas
palavras, não como uma string única**. Uma consulta `term` pedindo a string exata *card network
unavailable* não acha nada num campo de texto, porque nenhuma palavra do índice é essa string. A
consulta que casa a frase é `match_phrase`:

```
ana@obs:~/shop$ curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{"size": 2, "query": {"match_phrase": {"attributes.message": "card network unavailable"}}, "_source": ["attributes.order_id", "attributes.trace_id", "resource.attributes.service.name"]}' | jq -c '.hits.total, (.hits.hits[]._source)'
{"value":30,"relation":"eq"}
{"resource":{"attributes":{"service.name":"payments"}},"attributes":{"trace_id":"768ab0f2a4dea3556000545ca1e97bc5","order_id":600.0}}
{"resource":{"attributes":{"service.name":"payments"}},"attributes":{"trace_id":"1a5485344e8ebaf166c9bb79727677bf","order_id":580.0}}
```

Trinta falhas, cada uma com o id do rastro e o serviço. E como todo campo é indexado, contar linhas
**por serviço é respondido pelo índice**, sem ler uma linha:

```
ana@obs:~/shop$ curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{"size": 0, "aggs": {"by_service": {"terms": {"field": "resource.attributes.service.name"}}}}' | jq -r '.aggregations.by_service.buckets[] | [.key, .doc_count] | @tsv'
orders	602
payments	602
storefront	602
mailer	537
```

Essa é a força do Elasticsearch, e o motivo de ele ser a escolha comum quando logs são buscados como
dados: qualquer campo, qualquer combinação, qualquer agregação, na velocidade de uma consulta ao
índice. O preço foi pago quando cada linha chegou, em processador, memória e disco, e a última seção
desta aula o mede.
