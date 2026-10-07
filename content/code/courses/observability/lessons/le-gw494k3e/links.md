---
title: Links: when one piece of work has many causes
version: 2
---

A parent says *this span was caused by that one*, and a span has at most one. Some work does not
fit. **A job that processes a batch of twenty-two orders was caused, in a sense, by twenty-two
requests.** Making it the child of any one of them would be a lie about the other twenty-one, and
making it the child of all of them is impossible. OpenTelemetry's answer is the **link**: a
reference from a span to another span, in any trace, that says *this concerned that* without making
them one trace.

The nightly report is the lab's case. It counts the orders since a date and, for each one, adds a
link to the trace of the request that created it. It can do that because `orders` kept every order's
`traceparent`. This lesson has sent three checkouts so far; nineteen
more make twenty-two, and then the report is run by hand:

```sh
for i in $(seq 1 19); do checkout; done
```


```
ana@obs:~/shop$ docker compose run --rm report 2>&1 | grep -v Container | jq -c '{message, orders, paid, trace_id}'
{"message":"report written","orders":22,"paid":22,"trace_id":"2463827ff26f4bee6e7636585987181f"}
```

Its span carries one link per order, and Jaeger stores them as references of type `FOLLOWS_FROM`,
its name for a link:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/2463827ff26f4bee6e7636585987181f | jq -c '.data[0].spans[] | {operationName, references: (.references | length), refType: (.references | map(.refType) | unique)}'
{"operationName":"nightly report","references":22,"refType":["FOLLOWS_FROM"]}
```

The trace ids it links to are the checkouts' own, in the order the orders were stored:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/2463827ff26f4bee6e7636585987181f | jq -r '.data[0].spans[0].references[:3][].traceID'
f1523e868eabe70f75294e789580216e
ae937cc824d4843fbac8e390ddb3cc0c
f8cdb58e9faf2978f1d207747f46300b
ana@obs:~/shop$ docker compose exec postgres psql -U shop -tAc 'SELECT id, split_part(traceparent, chr(45), 2) FROM orders ORDER BY id LIMIT 3'
1|f1523e868eabe70f75294e789580216e
2|ae937cc824d4843fbac8e390ddb3cc0c
3|f8cdb58e9faf2978f1d207747f46300b
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Parent against link. On the left, a checkout's trace: POST /checkout is the parent of POST /orders, which is the parent of the mailer's span, even though the mailer ran 22.8 seconds later after the queue: one request, one trace. On the right, the nightly report: its own trace, with no parent, and dashed links to the traces of the 22 orders it counted. A link says this work concerned those spans; it does not make them one trace.\"><defs><marker id=\"pl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a parent: one request</text><rect x=\"60\" y=\"50\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /checkout</text><text x=\"170.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storefront</text><rect x=\"60\" y=\"120\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POST /orders</text><text x=\"170.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"60\" y=\"220\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders.placed process</text><text x=\"170.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mailer, 22.8 s later</text><path d=\"M170 92 L170 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M170 162 L170 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><text x=\"240\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">through the queue</text><text x=\"540\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">links: many causes, one job</text><rect x=\"450\" y=\"220\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nightly report</text><text x=\"540.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">report, no parent</text><rect x=\"370\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"400.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">order 1</text><path d=\"M540 218 L400 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><rect x=\"450\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"480.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">…</text><path d=\"M540 218 L480 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><rect x=\"530\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">…</text><path d=\"M540 218 L560 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><rect x=\"610\" y=\"70\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"640.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">order 22</text><path d=\"M540 218 L640 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#pl-ah)\"></path><text x=\"540\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22 links, one per order counted</text></svg>", "caption": "One cause and one effect is a parent. Many causes behind one piece of work, or none at all, is a root with links."}
```

A backend uses the links to move between the two kinds of trace. It can go from the report's span to
the checkouts it counted and, where the backend supports it, from a checkout to every batch that
later touched it. **Neither trace grows**: the report's trace is one span long, and each checkout's
trace is exactly what it was. That is the difference from a parent, and it is why links fit batches,
fan-in and anything else where many requests feed one piece of work.
