---
title: Where it stops
version: 1
---

Automatic instrumentation sees a service from its edges, and it is good at them. **It stops at
three places**, and each one is a question a real investigation asks.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"What automatic instrumentation sees in orders. The service is a box. Its edges are seen: the request arriving through Flask, the queries leaving through psycopg, the call to payments leaving through requests. Inside the box, unseen: which order this is, which product, the decision to publish to the queue, and the publish itself, because no instrumentation for the queue client is installed.\"><defs><marker id=\"edge-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"220\" y=\"60\" width=\"280\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">which order, which product</text><text x=\"360\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">paid or declined, and why</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the decision to publish</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">not seen</text><rect x=\"30\" y=\"120\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /orders</text><text x=\"100.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Flask, seen</text><path d=\"M172 145 L218 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#edge-ah)\"></path><rect x=\"550\" y=\"70\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">INSERT, UPDATE</text><text x=\"625.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">psycopg, seen</text><rect x=\"550\" y=\"130\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /charge</text><text x=\"625.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests, seen</text><rect x=\"550\" y=\"190\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"625.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">publish</text><text x=\"625.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pika, not seen</text><path d=\"M502 92 L548 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#edge-ah)\"></path><path d=\"M502 152 L548 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#edge-ah)\"></path><path d=\"M502 212 L548 212\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#edge-ah)\"></path></svg>", "caption": "Automatic instrumentation draws the edges of a service: every place it meets a library somebody instrumented. What happens between the edges is the code's own business, and only the code can say it."}
```

**It does not know what the request was about.** These are every attribute the `POST /orders` span
carried, keys only:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/09839a6961d8e8d4b0f0c10ba65e358c | jq -r '[.data[0].spans[] | select(.operationName == "POST /orders") | .tags[].key] | join(" ")'
otel.scope.name otel.scope.version http.flavor http.host http.method http.route http.scheme http.server_name http.status_code http.target http.user_agent net.host.name net.host.port net.peer.ip net.peer.port span.kind
```

Sixteen keys, and apart from the tracer's own name and version they are all about HTTP and the
network: the method, the route, the host,
the port, the client's address. Nothing says which order this was, which product, how much, or
whether it was paid. Flask cannot know: an order is the shop's idea, not the web framework's. So
*"show me the traces of orders for kettles"* has no answer in this service, and the storefront
could answer it only because somebody wrote `shop.sku` by hand.

**It does not cross a client it has no instrumentation for.** `orders` publishes each paid order to
RabbitMQ through `pika`, and no instrumentation for `pika` is installed. In the lab, two lines of
`publish()` carry the trace across anyway, written by hand. Here one of them is deleted, so the
service is exactly what automatic instrumentation alone would leave:

```
ana@obs:~/shop$ grep -n 'propagate' services/orders/app.py
15:from opentelemetry import propagate
34:    propagate.inject(headers)
ana@obs:~/shop$ sed -i '/propagate.inject(headers)/d' services/orders/app.py && docker compose restart orders 2>&1 | tail -1
 Container shop-orders-1 Started 
```

A checkout is sent, and the trace id the storefront logged is compared with the one the mailer
logged for the same order:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r '.trace_id'
a4d8efca1813239ebdbc363181dec65f
ana@obs:~/shop$ docker compose logs --no-log-prefix mailer | grep 'confirmation sent' | tail -1 | jq -r '.trace_id'
ebc950ea40b39675d6cab734439f924f
ana@obs:~/shop$ curl -s localhost:16686/api/traces/ebc950ea40b39675d6cab734439f924f | jq -r '.data[0] as $t | $t.spans[] | [$t.processes[.processID].serviceName, .operationName, (.references | length | tostring) + " parent"] | @tsv'
mailer	send confirmation	1 parent
mailer	orders.placed process	0 parent
```

**Two different trace ids for one checkout**, and the mailer's consumer span has no parent: it
became the root of a trace of its own. Nothing failed and nothing complained. The trace of the
checkout simply ends at `orders`, and the confirmation e-mail lives in a trace that nobody looking
at the checkout will ever find. Lesson 4 is entirely about this, including the instrumentation
package that exists for `pika` and why the lab writes the two lines instead.

**It does not see inside your own functions.** A loop that recalculates discounts, a cache lookup
in a dictionary, a call to a library nobody instrumented: to automatic instrumentation all of that is
the gap between two spans. In lesson 1's trace the slow part was found because payments' code had
wrapped the wait in a span of its own. Had the wait been there with no span around it, the trace
would have shown `POST /charge` taking 1501 ms and nothing inside it.

The two lines were put back, and `orders` was restarted, before anything else in this lesson ran.
