---
title: Propagation, the header that makes it one trace
version: 1
---

A trace crosses a service boundary in **one HTTP header**, defined by the W3C's Trace Context
recommendation and called `traceparent`. The box office writes it with `propagate.inject` on every
call to payments, and payments prints it as it arrives. One sale, then the last line of each
service's log:

```
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/2/tickets; echo
{"event": 2, "seat": 1, "code": "8b862c7b06ca08c1"}
ana@lab:~/tickets$ docker compose logs payments --no-log-prefix | tail -1
{"message": "charge", "traceparent": "00-5bd86167ca0ed7a647e37c1ebe501aac-b78031cb62daec0c-03"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep '"POST"' | tail -1
{"time": "2026-10-10T06:22:21.113+00:00", "level": "info", "message": "request", "host": "dd4bf75a071b", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 46.2, "trace_id": "5bd86167ca0ed7a647e37c1ebe501aac"}
```

The header is four fields separated by dashes:

| field | here | meaning |
|---|---|---|
| version | `00` | the format's version |
| trace id | `5bd86167ca0ed7a647e37c1ebe501aac` | the trace this request belongs to: the same as `trace_id` in the box office's log line |
| parent id | `b78031cb62daec0c` | the span that made this call, the box office's `charge` span, which becomes the parent of payments' span |
| flags | `03` | the `01` bit says the trace is sampled, so payments records its span too; the `02` bit, newer, says the trace id was generated at random |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"The traceparent header the box office sent to payments, split into its four fields: version 00, a 32-digit trace id shared by the whole trace, a 16-digit parent id naming the box office's charge span, and the flags 03, whose lowest bit says the trace is sampled.\"><rect x=\"40\" y=\"40\" width=\"30\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"55.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">00</text><text x=\"55.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">version</text><text x=\"80\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-</text><rect x=\"90\" y=\"40\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5bd86167ca0ed7a647e37c1ebe501aac</text><text x=\"225.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">trace id</text><text x=\"370\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">b78031cb62daec0c</text><text x=\"450.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">parent id</text><text x=\"530\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-</text><rect x=\"540\" y=\"40\" width=\"30\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"555.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">03</text><text x=\"555.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">flags</text><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same as trace_id in the box office's log</text><text x=\"400\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the charge span, parent of payments' span</text></svg>", "caption": "Four fields, and the second one is what makes two services one trace."}
```

That is the whole contract. Payments does not need the box office's SDK, language or vendor; it needs
to read four fields and pass them on. **A service in the middle that does not forward the header
breaks the trace in two**, and the most common cause of traces that stop at a service is exactly
that: a proxy, a queue or a hand-written HTTP client that drops unknown headers.

## A trace that starts outside

The box office continues a trace it receives, not only those it starts. Here a client sends its own
`traceparent`, the example from the W3C specification itself:

```
ana@lab:~/tickets$ curl -s -X POST -H 'traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01' localhost:8080/events/3/tickets; echo
{"event": 3, "seat": 1, "code": "aaec814f7270e014"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py
trace 0af7651916cd43dd8448eb211c80319c
POST /events/{id}/tickets      tickets   at   0.0 ms  took  43.8 ms
  charge                       tickets   at   0.1 ms  took  35.3 ms
    POST /charges              payments  at   1.9 ms  took  33.1 ms
  UPDATE events                tickets   at  35.8 ms  took   0.7 ms
  sign                         tickets   at  36.5 ms  took   5.0 ms
  INSERT tickets               tickets   at  41.6 ms  took   0.7 ms
```

**The trace id is the one the client chose**, `0af7651916cd43dd8448eb211c80319c`, and the box
office's root span is a child of the client's span `b7ad6b7169203331`, which Jaeger does not have
because the client never sent it. This is how one trace covers a browser, a load balancer, a gateway
and every service behind them: each one reads the header, continues the trace and passes it on.

Over a message queue the same identity travels in the message's headers instead of HTTP's, and
OpenTelemetry's propagators handle both.

## And the cost of a header

Accepting a `traceparent` from outside means a client can choose your trace ids and your sampling
decision. Systems that care put a gateway at the edge that starts a fresh trace for untrusted
callers, or records the caller's trace as a link rather than as a parent, so that nobody outside can
fill a tracing back end by asking for every request to be sampled.
