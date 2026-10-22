---
title: The Prometheus format, and what to alert on
version: 1
---

`/actuator/metrics` is for a person with curl. Nobody watches a production system that way: a
monitoring server asks every instance for all of its numbers at a fixed interval, keeps them as time
series, and raises an alert when a rule over them turns true. **Prometheus** is the common choice, and
it **pulls**: the application does not send anything anywhere, it answers when asked. That is the job
of the fourth endpoint, `/actuator/prometheus`, which the `micrometer-registry-prometheus` dependency
added. Installing Prometheus itself, and its query language, belong to `observability` lesson 5; what
this section reads is the contract between the two, the text the bookshop serves.

## The text format

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | wc -l
466
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep -E "bookshop_orders|^hikaricp_connections_(active|pending)"
# HELP bookshop_orders_total  
# TYPE bookshop_orders_total counter
bookshop_orders_total{outcome="out-of-stock"} 1.0
bookshop_orders_total{outcome="placed"} 2.0
hikaricp_connections_active{pool="bookshop-pool"} 0.0
hikaricp_connections_pending{pool="bookshop-pool"} 0.0
```

Every meter in the registry is in those lines, written for a program to read. Each family starts with
a `# HELP` line, the description, empty here because the counter was registered without one, and a
`# TYPE` line. Then comes one line per series: the name, the tags in braces, now called **labels**, and
the current value. The names changed on the way, by rules Micrometer applies for this backend:

| in Micrometer | in Prometheus |
|---|---|
| `bookshop.orders`, a counter | `bookshop_orders_total` |
| `hikaricp.connections.active`, a gauge | `hikaricp_connections_active` |
| `http.server.requests`, a timer in seconds | `http_server_requests_seconds_count`, `_sum` and `_max` |

Dots become underscores, a counter gains `_total`, and a timer becomes three series with its unit in
the name. A timer's count and sum are counters themselves:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep -E "^http_server_requests_seconds_(count|sum)" | grep "/books\""
http_server_requests_seconds_count{error="none",exception="none",method="GET",outcome="SUCCESS",status="200",uri="/books"} 2
http_server_requests_seconds_sum{error="none",exception="none",method="GET",outcome="SUCCESS",status="200",uri="/books"} 0.134895875
```

## A counter is read as a rate

`bookshop_orders_total{outcome="placed"}` is the number of orders since this process started. On its
own, that answers almost nothing: it drops to zero at every restart, and a big number may just mean a
long uptime. What a monitoring system reads is **how fast it grows**. Take two readings, place a few
orders in between, and the arithmetic is the same one Prometheus does:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep "^bookshop_orders_total"; date +%T
bookshop_orders_total{outcome="out-of-stock"} 1.0
bookshop_orders_total{outcome="placed"} 2.0
20:35:05
ana@vm:~/bookshop$ for book in 4 4 4 4 4 4 3 3; do curl -s -o /dev/null -w '%{http_code} ' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d "{\"lines\":[{\"bookId\":$book,\"quantity\":1}]}" localhost:8080/orders; done; echo
201 201 201 201 201 409 409 409 
ana@vm:~/bookshop$ sleep 15; curl -s localhost:8081/actuator/prometheus | grep "^bookshop_orders_total"; date +%T
bookshop_orders_total{outcome="out-of-stock"} 4.0
bookshop_orders_total{outcome="placed"} 7.0
20:35:20
```

The eight codes in the middle say what happened: Persuasion had five copies, so its sixth order was
refused, and Frankenstein had none left for either of the last two. Fifteen seconds apart, `placed`
went from 2 to 7 and `out-of-stock` from 1 to 4. Five orders in fifteen seconds is a third of an order
a second, and three refusals is 0.2 a second. That division, repeated over a sliding window of
scrapes, is what Prometheus's `rate()` returns, and it copes with a restart: a counter that falls is
read as a process that started again, never as orders taken back.

## What would wake somebody up

An alert is a rule over these series that sends a message to a person. Every alert that fires and needs
nobody teaches the person on call to ignore the next one, so a good rule watches what a customer feels,
or what is about to make them feel it, and nothing else. For the bookshop, four candidates, written as
a Prometheus rules file. **This file was not loaded into a Prometheus in this course**, so nothing
here is a captured result; it shows how each question becomes an expression over the series above.

```yaml
groups:
  - name: bookshop
    rules:
      - alert: BookshopDown
        expr: up{job="bookshop"} == 0
        for: 1m
      - alert: BookshopServerErrors
        expr: |
          sum(rate(http_server_requests_seconds_count{job="bookshop", outcome="SERVER_ERROR"}[5m]))
            / sum(rate(http_server_requests_seconds_count{job="bookshop"}[5m])) > 0.05
        for: 5m
      - alert: BookshopPoolWaiting
        expr: hikaricp_connections_pending{job="bookshop", pool="bookshop-pool"} > 0
        for: 2m
      - alert: BookshopOrdersRefused
        expr: |
          sum(rate(bookshop_orders_total{job="bookshop", outcome="out-of-stock"}[1h]))
            / sum(rate(bookshop_orders_total{job="bookshop"}[1h])) > 0.2
        for: 30m
```

`up` is a series Prometheus writes itself for every target: `1` when the last scrape answered, `0`
when it did not, which covers a process that died, a machine that is gone and a port that stopped
answering. The second rule is the share of requests that failed on the server, over five minutes,
which is the symptom a customer meets. The third is lesson 14's exhaustion, caught while requests are
still waiting rather than after they time out. `job` is a label Prometheus adds to every series it
scrapes, from its own configuration, so a rule names one application.

The fourth is the bookshop's own counter, and it is a different kind of alert. More than a fifth of
orders refused for lack of stock, for half an hour, is a buying problem rather than an outage. It
belongs in a ticket for whoever orders books, not on somebody's phone at three in the morning.

Run the outage from the health section past these rules. `up` stayed at 1, because the management
server kept answering the scrape, so the first rule is silent: the process was alive, and that is all
it asks. The second fires. The client was told 401, but the timer recorded a `500` with
`SERVER_ERROR`, and with every request that needs the database failing, the share is far above five
per cent. The third fires too, if the outage lasts two minutes with requests arriving, because each of
them waits five seconds for a connection. Here the numbers were truer than the
response the client got.
