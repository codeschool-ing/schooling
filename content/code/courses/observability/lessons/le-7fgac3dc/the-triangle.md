---
title: Three views, and what joins them
version: 1
---

The slow checkout was found in an order, and the order is the lesson. **The metric said that
something was wrong and how much**: checkouts went from milliseconds to seconds. **The trace said
where**: one wait in payments. **The log said what each service did about it**, in its own words.
None of the three could have done the other two's work. The metric aggregates away every individual
request; a single trace cannot tell you whether it is typical; a log line knows only the moment it
was written.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The three signals as a triangle. Metric at the top: that something is wrong, and how much. Trace at the bottom left: where, in which service and which call. Log at the bottom right: why, in the program's own words. Between metric and trace: the time window and the service. Between trace and log: the trace id written in every line. Between metric and log: the service name, the one label they share.\"><defs><marker id=\"tri-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"20\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">metric</text><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">that, and how much</text><rect x=\"60\" y=\"220\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trace</text><text x=\"140.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">where</text><rect x=\"500\" y=\"220\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">log</text><text x=\"580.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">why</text><path d=\"M290 86 L190 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M430 86 L530 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M222 252 L498 252\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time window</text><text x=\"170\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and service</text><text x=\"560\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">service</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">trace_id</text><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in every log line</text></svg>", "caption": "Three views of the same events, and what joins each pair. The join is what lets an investigation move from one to the next without starting over."}
```

**What makes them one investigation instead of three is what they share.** A trace and a log line
share the trace id, which is why the shop writes it into every line. A metric and a trace share the
service and a time window: the metric says when, and you open a trace from that window. A metric and
a log share almost nothing but the service name, which is why moving between those two is the
slowest step and why the order above goes through the trace. Lesson 7 makes these joins clickable in
Grafana, and lesson 11 adds the last one: a metric that carries the id of an example trace.

The three also cost differently, and that shapes how much of each a team can afford:

| | grows with | rough cost per request | kept for |
|---|---|---|---|
| metric | number of label combinations, not traffic | nothing extra | months |
| log | every event written | one line per event, often several per request | days to weeks |
| trace | every request traced | one span per step | days, and often only a sample |

These are tendencies rather than laws. Lessons 6, 10 and 12 each take one row and show where it
breaks: a metric whose labels multiply, logs whose volume becomes the bill, and traces that have to
be sampled.

**Every signal in this lesson exists because the shop was written to produce it.** The histogram is
about forty lines in the shop's code, the JSON lines are a log formatter, and the spans are an SDK
set up at start-up plus a few names chosen by hand. Lesson 2 opens the storefront and writes its
spans from the beginning.
