---
title: The same trace in Zipkin
version: 1
---

Zipkin is older: Twitter published it in 2012, after Google's paper on Dapper, and Jaeger borrowed
much of its model. The lab's Collector sends every span to both, so the same checkout can be read
in Zipkin's API:

```
ana@obs:~/shop$ curl -s localhost:9411/api/v2/trace/2317d16ea481cf7a0350d6d965f983e9 | jq -r 'sort_by(.timestamp) | .[] | [.localEndpoint.serviceName, .kind // "-", .name, "\(.duration / 1000 | floor) ms"] | @tsv'
storefront	SERVER	post /checkout	439 ms
orders	SERVER	post /orders	436 ms
orders	CLIENT	insert	1 ms
orders	CLIENT	post	404 ms
payments	SERVER	post /charge	401 ms
payments	-	wait for the card network	400 ms
orders	CLIENT	update	1 ms
mailer	CONSUMER	orders.placed process	20 ms
mailer	-	send confirmation	20 ms
```

**The same nine spans with the same durations**, in Zipkin's own spelling: names are lower case,
and each span carries its kind. The kind is how Zipkin knows which side of a call a span is on:
`CLIENT` is `orders` making the call to payments, `SERVER` is payments answering it, and `CONSUMER`
is the mailer taking a message. A span with no kind, `-` here, is internal work, like the wait the
payments code opens by hand.

That the two stores agree is the point of exporting OTLP and letting the Collector translate. **The
services were written once**, and the choice of store is a line in a configuration file, which is
why the lab can run both side by side.

Zipkin's distinctive answer is the **dependency graph**: from every trace in a window it counts which
service called which, and how often:

```
ana@obs:~/shop$ curl -sG localhost:9411/api/v2/dependencies --data-urlencode endTs=$(date +%s000) --data-urlencode lookback=300000 | jq -r '.[] | [.parent, .child, .callCount, (.errorCount // 0)] | @tsv'
orders	payments	472	0
storefront	orders	452	0
```

The map of the shop drawn from traffic alone: the storefront calls orders, orders calls payments,
450 to 470 times in five minutes, with no errors. Nobody wrote it down, so it cannot be out of
date, and it is what a newcomer reads to learn how a system is put together.

**The mailer is missing**, although it is in every trace above. The graph is built from pairs of
client and server spans, and from producer and consumer spans that name the broker between them.
The mailer's span names no broker and `orders` records no producer span, so the queue leaves no
edge. A map drawn from traces shows exactly what the instrumentation records, and an edge it lacks
is a question about the instrumentation before it is a fact about the system.
