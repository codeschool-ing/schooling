---
title: Choosing between them
version: 1
---

All three stored the same lines and answered the same questions, so the choice is not about what
they can find. **It is about where each one pays**, and that follows from how it indexes:

| | Loki | Elasticsearch | Graylog |
|---|---|---|---|
| indexes | the labels of each stream | every field of every line | every field, in OpenSearch underneath |
| query language | LogQL, close to PromQL | its query DSL, and others on top | its own search syntax |
| cheap | writing and storing; it compresses chunks and keeps them in object storage | searching many fields at once, and aggregating | the same as Elasticsearch |
| expensive | a search over many streams with only a line filter | memory, disk and the index on every write | the same, plus MongoDB and Graylog itself |
| comes with | Grafana, for reading | Kibana, which this lab does not run | its own interface, streams and alerts |
| typical home | teams already on Prometheus and Grafana | teams that search logs as data, security and analytics | teams that want one product for logs, with roles and alerts |

**Two warnings that hold whichever is chosen.** A log store's cost is driven by the volume it is
sent, which is why lesson 8's advice comes before any of these and lesson 10's retention comes
right after. And labels in Loki carry the same danger as labels in Prometheus: a label per request,
user or trace id is a stream per value, and the small index that makes Loki cheap stops being small.
Values like those belong in the line, where `| json` and a filter find them.

The Elastic Stack's other parts, **Logstash** or **Beats** for shipping and **Kibana** for reading,
are left out of this lab on purpose: the Collector already ships, and Kibana's screens are a product
that changes faster than this course. What the lab shows is the part that decides the cost, the
index, and the query that reaches it.
