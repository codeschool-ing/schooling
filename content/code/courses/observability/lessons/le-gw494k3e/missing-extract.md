---
title: One missing argument
version: 1
---

Propagation fails quietly, and the way to recognise the symptom is to cause it once. Payments'
extract is kept, but the context it returns is no longer used to start the span:

```
ana@obs:~/shop$ grep -n 'context=ctx' services/payments/app.py
46:    with tracer.start_as_current_span("POST /charge", context=ctx, kind=SpanKind.SERVER) as span:
ana@obs:~/shop$ sed -i 's/, context=ctx, kind=SpanKind.SERVER/, kind=SpanKind.SERVER/' services/payments/app.py && docker compose restart payments 2>&1 | tail -1
 Container shop-payments-1 Started 
```

A checkout, and the trace ids the storefront and payments logged for it:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r .trace_id
ae937cc824d4843fbac8e390ddb3cc0c
ana@obs:~/shop$ docker compose logs --no-log-prefix payments | grep 'charge decided' | tail -1 | jq -r .trace_id
ec2f711fe663aea741f0cc263469fb72
```

**Two trace ids for one checkout**, the same symptom lesson 3 met at the queue, this time over plain
HTTP. The header still arrived and was still extracted. Without `context=ctx` the span simply
started from payments' own current context, which is empty at the start of a request, so it became
the root of a new trace. And the checkout's trace, read from the storefront's side:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/ae937cc824d4843fbac8e390ddb3cc0c | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[] | [$t.processes[.processID].serviceName, .operationName] | @tsv'
storefront	POST /checkout
orders	POST /orders
orders	INSERT
orders	POST
orders	UPDATE
mailer	orders.placed process
mailer	send confirmation
```

Seven spans, every service but one, and **nothing in the trace says one is missing**. `orders`' `POST`
went out and came back, so its span is complete; the work it caused is filed under another id.
Nobody gets an error, the checkout works, both traces look healthy on their own. The only clue is a
client span with no server span under it, and a service whose traces all have a single root.

Two habits catch it. Look at a trace of every new service and check that the first span has a
parent from another service. And in a service instrumented by hand, **treat `extract` and the span
that uses it as one unit**, never two lines that can drift apart in an edit. The original
`app.py` was put back and payments restarted before the next section.
