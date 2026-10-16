---
title: A trace, and why metrics and logs are not enough
version: 1
---

Lesson 8 measured the API's latency and lesson 9 read its logs. Both describe **one service**. A
checkout crosses three: the API, the payments service, and the card network behind it, each with its
own metrics and its own log group. When checkout is slow, each team's dashboard can be green: each
service is fast at what it does, and the time goes somewhere between them. **A trace follows one request
across every service it touches**, and says where its time went.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A waterfall of one checkout trace. The API&#x27;s segment, shop-api, runs from 0 to 512 milliseconds. Inside it, a subsegment for orders-db takes 27 milliseconds and a call to payments takes 470. The payments service&#x27;s own segment starts 6 milliseconds after the call and takes 457, and inside it a subsegment for the card network takes 420 milliseconds.\"><defs><marker id=\"wf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-api</text><text x=\"120\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the API's segment</text><rect x=\"230.0\" y=\"28\" width=\"450.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"238.0\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">512 ms</text><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders-db</text><text x=\"120\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subsegment</text><rect x=\"233.5\" y=\"64\" width=\"23.8\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"263.3\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">27 ms</text><text x=\"20\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payments</text><text x=\"120\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">call, in the API</text><rect x=\"260.8\" y=\"100\" width=\"413.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.8\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">470 ms</text><text x=\"20\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payments</text><text x=\"120\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">payments' segment</text><rect x=\"266.1\" y=\"136\" width=\"402.2\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"674.2\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">457 ms</text><text x=\"20\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">card-network</text><text x=\"120\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subsegment</text><rect x=\"274.0\" y=\"172\" width=\"369.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"649.6\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">420 ms</text><path d=\"M230 214 L680.56 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"230\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"680.56\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">512 ms</text></svg>", "caption": "The numbers are the segments this lesson writes. Most of the request is spent two services away."}
```

The vocabulary is small:

- a **trace** is one request's whole journey, with one **trace id** shared by every part;
- a **segment** is the part one service handled, from the moment the request arrived to the moment it
  answered;
- a **subsegment** is a piece of a segment: a database query, a call to another service, a block of
  code worth timing;
- a **parent id** connects a service's segment to the subsegment in the caller that made the call.

The ids travel with the request. On AWS the carrier is an HTTP header, `X-Amzn-Trace-Id`, holding the
trace id, the parent's id and a sampling decision: `Root=1-6ad25543-8f4d3e27dda1494c73cf256d;Parent=53995c3f42cd8ad8;Sampled=1`.
A load balancer adds the header if it is missing, every instrumented service passes it on, and a service
that drops it breaks the trace in two.

## Metrics, logs and traces

The three answer different questions, and an incident uses them in that order:

| | answers | example |
|---|---|---|
| metrics | is something wrong, and since when | checkout p99 rose from 400 ms to 1.4 s at 14:02 |
| traces | where in the chain the time or the error is | 420 of 512 ms waiting on the card network |
| logs | what exactly happened there | the card network answered `timeout` for customer c-1027 |

A trace id written into each log line joins the last two: from a slow trace, find its log lines; from
an error line, find the trace. **Write the trace id into every structured log line**, which is one
field in lesson 9's JSON.
