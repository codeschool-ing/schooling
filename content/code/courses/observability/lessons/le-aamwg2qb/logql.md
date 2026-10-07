---
title: LogQL: filters, parsers, and metrics from logs
version: 2
---

LogQL, Loki's query language, is a stream selector followed by a pipeline of stages separated by
`|`. Payments fails one charge in twenty since the start of the lesson, so there is something to find. The simplest stage
is a **line filter**, `|= "text"`, which keeps lines containing the text, like `grep`:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} |= "card network"' --data-urlencode limit=2 | jq -r '.data.result[].values[][1]' | jq -c '{level, message, order_id}'
{"level":"ERROR","message":"card network unavailable","order_id":620}
{"level":"ERROR","message":"card network unavailable","order_id":640}
```

A **parser** turns each line into labels for the rest of the pipeline, and lesson 8's JSON makes
that one word: `| json`. After it, any field can be filtered on by name, here the declined cards:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} | json | approved="false"' --data-urlencode limit=2 | jq -r '.data.result[].values[][1]' | jq -c '{message, order_id, approved}'
{"message":"charge decided","order_id":619,"approved":false}
{"message":"charge decided","order_id":637,"approved":false}
```

**The filter runs on fields, but nothing was indexed to make it possible**: Loki parsed every
payments line in the range to find these. That is fine for a few minutes of one service and slow for
a month of all of them. It is why a line filter that narrows cheaply, `|= "approved\": false"`,
is often put in front of the parser.

LogQL can also turn lines into numbers. `count_over_time` counts lines in a window, and with
`sum by` it reads like PromQL:

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

Lines per service in the last minute, and payments' lines in the last five by message: **615
charges decided and 32 card-network failures**. That is about one in twenty as configured, give or take the edges
of the window. These are metrics computed from logs at query time, useful for a question nobody made
a metric for in advance. For anything asked every fifteen seconds by a dashboard or an alert, the
service's own counter from lessons 5 and 6 is far cheaper.
