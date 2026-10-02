---
title: Graylog: a log product on the same kind of index
version: 1
---

Graylog stores its lines in OpenSearch, an open-source fork of Elasticsearch, so its index works the
way the previous section described. **What it adds is the product around it**: inputs that receive
many formats, *streams* that route lines by rules, users and permissions per stream, alerts on
searches, and an interface built for people who read logs all day. Its MongoDB holds that
configuration; the lines themselves are in OpenSearch.

The input created earlier is listening, on the port OTLP over gRPC uses:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' localhost:9000/api/system/inputs | jq -r '.inputs[] | [.title, .attributes.port] | @tsv'
shop logs (OTLP)	4317
```

Graylog files each field it receives under a name of its own, prefixed by where it came from: the
shop's `order_id` is `otel_attributes_order_id` here, and the service is
`otel_resource_attributes_service_name`. Its search syntax is field and value, and the API can answer
in CSV:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Accept: text/csv' 'localhost:9000/api/search/universal/relative?query=otel_attributes_message:%22card%20network%20unavailable%22&range=600&limit=2&fields=timestamp,otel_attributes_order_id,otel_attributes_trace_id'
"timestamp","otel_attributes_order_id","otel_attributes_trace_id"
"2026-10-02T15:41:33.000Z","300.0","cbb05aede41b48fa7c79060630ba8a52"
"2026-10-02T15:41:38.000Z","320.0","ac2e32e38ebc87cd1c31c2630275fe46"
```

The same failures, two of them, with their order ids and trace ids. **The prefixes are worth noticing
before writing anything against them.** Every store renames fields on the way in. Elasticsearch
nests them under `attributes.`, Graylog flattens them with `otel_attributes_`, and Loki leaves them in the
line. A query, dashboard or alert copied from one store to another fails on the names before it
fails on anything else.
