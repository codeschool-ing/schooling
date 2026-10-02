---
title: One failed checkout, in all three
version: 1
---

The test that matters is the one an investigation runs: one failed checkout, found by its trace id,
in every place its lines went. The newest failure's trace id is taken from payments' own output, and
the script waits for the batches to land before asking:

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

**The same failure in all three**, with one difference that is the selector's and not the store's:
the Loki query named `{service_name="payments"}` and found payments' line; Elasticsearch and Graylog
were asked for the trace id in every service's lines and found three, payments' *card network
unavailable*, orders' *payment failed* and the storefront's *checkout failed*. Removing the label
from the Loki query would have found all three there too, at the cost of reading every stream.

And Jaeger, asked for the same id, lists the spans of that checkout that ended in error:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/0232ecb24f137876488caaa13f510759 | jq -r '.data[0].spans[] | select(.tags[] | select(.key == "error" and .value == true)) | .operationName'
POST /charge
POST /checkout
POST
POST /orders
```

**Four failed spans, from the charge up to the checkout**, the same chain lesson 1 read for a slow
request. The logs say what each service decided; the trace says how the failure travelled. Lesson 11
links the two inside Grafana, so the id is clicked rather than copied.

The price of keeping three stores is visible from the outside:

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

**Loki, 80 MB. Elasticsearch, 1.5 GB. Graylog and its two companions, about 1.8 GB.** These are the
same lines, a few thousand of them, on stores that were all configured small; most of the JVMs'
memory is a heap reserved up front, and none of these numbers scales linearly with traffic. What
they show is the shape of the trade in this lesson's figure: Loki keeps writing cheap and pays when it
reads; the other two pay to index every line, and keep the memory to do it. The fault file and the
override were removed at the end of the capture.
