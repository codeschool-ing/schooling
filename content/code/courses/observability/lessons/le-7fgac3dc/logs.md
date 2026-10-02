---
title: A log: one event, with fields
version: 1
---

Every service of the shop writes one line per event to its standard output, and each line is a
JSON object. This is the last checkout the storefront logged, made readable by `jq`:

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

**A log line describes one thing that happened**, so it can carry what a metric cannot: this order,
number 111, this product, this outcome. It is also why logs cost more than metrics as traffic
grows: a million checkouts are a million of these. Lesson 8 is about what goes in a line and lesson
10 about what it costs.

Two fields matter more than they look. `trace_id` is the id of the request this line belongs to,
the same in every service that request touched, and **it turns separate logs into one story.**
Searching the other services' logs for it:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix payments orders | grep fcc594a0f3c6f9b924cc45718927651c | jq -c '{service, message, order_id}'
{"service":"payments","message":"charge decided","order_id":111}
{"service":"orders","message":"order stored","order_id":111}
```

The same checkout, seen by `payments` and by `orders`. `docker compose logs` only reaches the
containers on this machine, though, and a production system runs on dozens. That is why the lab
also sends every line, through the Collector, to Loki, which stores them all in one place and can
be asked the same question:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="payments"} |= "fcc594a0f3c6f9b924cc45718927651c"' | jq -r '.data.result[].values[][1]' | jq -c '{level, message, order_id}'
{"level":"INFO","message":"charge decided","order_id":111}
```

Read these lines looking for the slow second and a half, and **nothing in them mentions it.** The
charge was decided and the order was stored; each line is true. A log says what a program chose to
say at the moments it chose to say it, and nobody wrote "I am about to wait 1.5 seconds". You could
work the time out from the `time` fields of lines in four services, if every clock agreed to the
millisecond, and the next signal measures it for you, inside each service.
