---
title: The traceparent header
version: 1
---

Each service keeps its current span in its own memory, as lesson 2 showed, and memory does not
cross a network. **What crosses is a header.** `orders` happens to store the one it received with
every order, in a column of its own, so the header can be read straight out of the database after a
checkout:

```
ana@obs:~/shop$ docker compose exec postgres psql -U shop -tAc 'SELECT id, traceparent FROM orders ORDER BY id DESC LIMIT 1'
1|00-f1523e868eabe70f75294e789580216e-b0844e71b749fd8f-03
```

That string is the **`traceparent`** header defined by the W3C's Trace Context recommendation, and
every OpenTelemetry SDK writes and reads it. It has four fields separated by hyphens:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The traceparent header orders received, split into its four fields. 00 is the version. f1523e868eabe70f75294e789580216e, 32 hexadecimal digits, is the trace id, the same in every service. b0844e71b749fd8f, 16 digits, is the parent id: the span id of the storefront span that made the call. 03 is the flags: bit 1 says the trace is sampled, bit 2 that the trace id is random.\"><defs><marker id=\"tp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">traceparent: 00-f1523e868eabe70f75294e789580216e-b0844e71b749fd8f-03</text><rect x=\"20\" y=\"80\" width=\"100\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">version</text><text x=\"70.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00</text><text x=\"70.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">always 00 today</text><path d=\"M70.0 44 L70.0 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><rect x=\"130\" y=\"80\" width=\"250\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trace id</text><text x=\"255.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32 hex digits</text><text x=\"255.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the same in every service</text><path d=\"M255.0 44 L255.0 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><rect x=\"390\" y=\"80\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">parent id</text><text x=\"475.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 hex digits</text><text x=\"475.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the caller's span id</text><path d=\"M475.0 44 L475.0 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><rect x=\"570\" y=\"80\" width=\"135\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"637.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">flags</text><text x=\"637.5\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">03</text><text x=\"637.5\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sampled, random id</text><path d=\"M637.5 44 L637.5 78\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storefront wrote it from its current span; orders reads it and makes that span the parent of its own</text></svg>", "caption": "Fifty-five characters carry everything a service needs to join a trace: which trace, and which span is its parent."}
```

The second field is the checkout's trace id. The third is not the trace's first span in general:
**it is the span that made the call**, whichever one was current when the request left. Jaeger
confirms it, with the first three spans of the same trace:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f1523e868eabe70f75294e789580216e | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[:3][] | [$t.processes[.processID].serviceName, .operationName, .spanID] | @tsv'
storefront	POST /checkout	b0844e71b749fd8f
orders	POST /orders	f88ce9d4a6b5790a
orders	INSERT	da0ba127ae104cef
```

`b0844e71b749fd8f` is the storefront's `POST /checkout`, the span that was current when the
storefront called `orders`. It is the parent of `orders`' own `POST /orders`. Each hop rewrites the
third field with its own span id, so the next service hangs its spans under the right parent, while
the second field never changes.

The last field carries the sampling decision, which lesson 12 depends on: the low bit says *this
trace is being recorded*, so every service downstream records it too. The bit above it, set here,
says the trace id was generated at random, which some sampling schemes rely on.

Which headers an SDK writes is a setting, `OTEL_PROPAGATORS`, and the lab leaves it at its default:

```
ana@obs:~/shop$ docker compose exec orders env | grep OTEL_PROPAGATORS || echo 'OTEL_PROPAGATORS not set'
OTEL_PROPAGATORS not set
```

Unset means `tracecontext,baggage`: the W3C `traceparent` above and a second header, `baggage`,
which this lesson's last section is about. Other formats exist, and Zipkin's **B3** is the one met
most. A system migrating between them can list two propagators, so that every service writes both
until the last old one is gone. Lesson 11 meets B3.
