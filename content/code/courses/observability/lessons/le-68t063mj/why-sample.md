---
title: Why traces are sampled
version: 2
---

Lesson 1 put traces at the expensive end of its table: one span per step, for every request traced.
Here is what that means in the lab, with five simulated customers buying and every trace kept.
Start the lab again from nothing, and set the customers going for half an hour:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 1800
sleep 90
```

Then:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))'
  4.533333333333333
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  35.53333333333333
```

About four and a half checkouts a second become 35.5 spans a second arriving at the Collector, about
eight for each checkout once the declines, the mailer and the database calls are counted. That is
about three million spans a day from a shop that is barely busy. **A span is far larger than a
metric's sample**: it carries a name, two ids, two timestamps, a status and every attribute somebody
added.

Three things grow with it: the Collector's work, the network between it and the store, and the
store, which has to index every span so that lesson 11's searches are fast. A metric does not grow
with traffic at all, as lesson 6 showed: its cost is its label combinations. A trace grows with
every request, which is why **traces are the signal that gets sampled**. Metrics are kept whole, and
logs, as lesson 8 showed, are thinned only at their most routine levels.

Sampling is not the same as losing data at random. It is a decision about which requests are worth
keeping as a whole story. The rest of the lesson is about the two places that decision can be made:
**at the head**, when the request begins, and **at the tail**, when it has ended.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One checkout on a time axis, and the moment each kind of sampling decides. Head sampling decides at the storefront's first span, before orders, payments or the mailer have done anything, so it cannot know whether the checkout will be slow or fail. The decision travels in traceparent to every service. Tail sampling decides in the Collector after a wait of ten seconds from the trace's first span, when every span has arrived, so it can keep errors and slow traces.\"><defs><marker id=\"hd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M150 230 L690 230\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#hd-ah)\"></path><text x=\"690\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><text x=\"20\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storefront</text><rect x=\"150.0\" y=\"60\" width=\"176.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"152.0\" y=\"94\" width=\"172.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">payments</text><rect x=\"162.0\" y=\"128\" width=\"160.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mailer</text><rect x=\"330.0\" y=\"162\" width=\"8.0\" height=\"16\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M150 40 L150 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"154\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">head: decides here, knows nothing yet</text><path d=\"M550.0 40 L550.0 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"546.0\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tail: decides here,</text><text x=\"546.0\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">after decision_wait</text><text x=\"170\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the decision rides in traceparent to every service</text></svg>", "caption": "Head sampling decides first and knows nothing; tail sampling decides last and knows everything, at the price of holding every trace until then."}
```

The trade is in the figure. The head is the cheapest place to decide, because a trace that is not
kept costs nothing from its first span on. But nothing has happened yet, so the decision cannot
depend on what will happen. The tail can keep exactly the failures and the slow requests, but only
by receiving every span first.