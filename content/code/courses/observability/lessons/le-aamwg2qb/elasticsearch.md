---
title: Elasticsearch: index everything on the way in
version: 1
---

Elasticsearch makes the opposite decision. **Every field of every line is indexed as it arrives**,
in an *inverted index*: for each word and each value, the list of documents that contain it. The
Collector's exporter writes the lines into a data stream named after OpenTelemetry's conventions:

```
ana@obs:~/shop$ curl -s 'localhost:9200/_cat/indices/logs-*?h=index,health,docs.count,store.size'
.ds-logs-generic.otel-default-2026.10.02-000001 yellow 2169 806.7kb
```

2169 documents and 807 KB, the index included. To index a field, Elasticsearch has to decide what
type it is, and it decides from the values it is sent, a **mapping**:

```
ana@obs:~/shop$ curl -s 'localhost:9200/logs-generic.otel-default/_mapping/field/attributes.order_id,attributes.message' | jq -c '.[].mappings | map_values(.mapping | to_entries[0].value.type)'
{"attributes.order_id":"float","attributes.message":"match_only_text"}
```

`order_id` became a `float`, because the Collector forwards every JSON number as a double, and
`message` became text, split into words for searching. Both are decisions with consequences: a
float order id compares and sorts as a number but prints as `600.0`, and **a text field is searched
by its words, not as one string**. A `term` query asking for the exact string *card network
unavailable* finds nothing in a text field, because no single word in the index is that string.
The query that matches the phrase is `match_phrase`:

```
ana@obs:~/shop$ curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{"size": 2, "query": {"match_phrase": {"attributes.message": "card network unavailable"}}, "_source": ["attributes.order_id", "attributes.trace_id", "resource.attributes.service.name"]}' | jq -c '.hits.total, (.hits.hits[]._source)'
{"value":30,"relation":"eq"}
{"resource":{"attributes":{"service.name":"payments"}},"attributes":{"trace_id":"768ab0f2a4dea3556000545ca1e97bc5","order_id":600.0}}
{"resource":{"attributes":{"service.name":"payments"}},"attributes":{"trace_id":"1a5485344e8ebaf166c9bb79727677bf","order_id":580.0}}
```

Thirty failures, each with its trace id and service. And because every field is indexed, counting
lines **by service is answered from the index**, without reading a line:

```
ana@obs:~/shop$ curl -s -H 'Content-Type: application/json' localhost:9200/logs-generic.otel-default/_search -d '{"size": 0, "aggs": {"by_service": {"terms": {"field": "resource.attributes.service.name"}}}}' | jq -r '.aggregations.by_service.buckets[] | [.key, .doc_count] | @tsv'
orders	602
payments	602
storefront	602
mailer	537
```

That is Elasticsearch's strength, and the reason it is the usual choice when logs are searched as
data: any field, any combination, any aggregation, at the speed of an index lookup. The price was
paid when each line arrived, in processor time, memory and disk, and the last section of this lesson
measures it.
