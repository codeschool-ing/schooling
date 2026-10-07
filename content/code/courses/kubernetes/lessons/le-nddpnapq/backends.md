---
title: Three signals, and what stores them
version: 1
---

The cluster's components expose metrics; the shop does not:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/metrics
shop 1.0 on shop-774b84ff8c-5tnl8
```

**`/metrics` on the shop returns its ordinary page**, because it answers every path the same way. It
publishes no counters of its own, so a monitoring system would know how much CPU it uses but not how
many orders it took or how many failed. That half is written into the application, with a client
library, and nothing in Kubernetes can supply it.

| signal | answers | collected by | stored and searched in, commonly |
|---|---|---|---|
| metrics | how much, how often, how fast, over time | scraping `/metrics` | Prometheus, and services built on it |
| logs | what exactly happened, line by line | a collector on every node | Loki, Elasticsearch |
| traces | where one request spent its time across services | the application, through OpenTelemetry | Jaeger, Tempo |

**OpenTelemetry is the common thread**: one set of libraries and one collector that can produce all
three signals in standard formats, so the choice of where to store them stays open. Nothing of this
was installed for this course, so this section describes and does not run them.

::: track devops
The `observability` course, later in your track, builds this stack: Prometheus in its lesson 5,
instrumenting a service with OpenTelemetry in its lesson 2, and tracing in its lesson 11.
:::

::: track *
The `observability` course builds this stack: Prometheus in its lesson 5, instrumenting a service with
OpenTelemetry in its lesson 2, and tracing in its lesson 11.
:::
