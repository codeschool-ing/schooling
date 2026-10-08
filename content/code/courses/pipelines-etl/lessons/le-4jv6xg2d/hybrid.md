---
title: Hybrid, and how to choose
version: 1
---

**The choice is not batch or streaming. It is how old an answer may be when somebody reads it.**
Put that number on each question first, and the kind of ingestion follows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l01-freshness\" aria-label=\"A line from seconds to a day, measuring how old an answer may be when it is read. Three questions sit on it: whether a book is in stock now, at seconds; which books sold this morning, at an hour; sales per shop last month, at a day. Below the line, three bands: a stream covers seconds to a minute, a micro-batch minutes to an hour, and a batch hours to a day.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70.0 120.0 L670.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M70.0 115.0 L70.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 second</text><path d=\"M263.3 115.0 L263.3 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"263.3\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 minute</text><path d=\"M456.7 115.0 L456.7 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"456.7\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 hour</text><path d=\"M650.0 115.0 L650.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 day</text><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">how old the answer may be when somebody reads it</text><circle cx=\"78.0\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M78.0 114.0 L78.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"78.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">is this book in stock now?</text><circle cx=\"456.7\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M456.7 114.0 L456.7 80.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"456.7\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">which books sold this morning?</text><circle cx=\"650.0\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M650.0 114.0 L650.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"650.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sales per shop last month</text><rect x=\"70.0\" y=\"150.0\" width=\"193.3\" height=\"22.0\" rx=\"11\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"166.7\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream</text><rect x=\"233.3\" y=\"180.0\" width=\"223.3\" height=\"22.0\" rx=\"11\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">micro-batch</text><rect x=\"426.7\" y=\"150.0\" width=\"223.3\" height=\"22.0\" rx=\"11\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"538.3\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">batch</text></svg>", "caption": "Put an age on each question first. The kind of ingestion is whatever band the age falls in, and the cheapest one that reaches it wins."}
```

Most of the space between the two ends is taken by the compromises:

- **Micro-batch.** A batch with a short period — every five minutes, every minute. Each run is a
  bounded piece that can be rerun, and the answer is a few minutes old. Spark Structured
  Streaming, in its default mode, works this way inside.
- **A stream for now, a batch for the record.** The website's events feed a live counter on a
  screen, and the same events are loaded again each night, complete and de-duplicated, into the
  warehouse. The architecture with two paths has a name, *lambda*, and its cost is the same logic
  written twice that must agree.
- **One stream, replayed for history.** Keep every event in a log long enough to read it again, and
  the "batch" becomes the same streaming code run over old events. That one is called *kappa*, and
  it moves the cost from writing the logic twice to keeping the log.

## Choosing, for Ponto Final

| question | how old may the answer be | what feeds it |
|---|---|---|
| sales per shop last month | a day | the nightly batch |
| which books sold this morning | an hour | a micro-batch every hour |
| is this book in stock now | seconds | a stream, or no pipeline at all — ask the source |

The last row is the one people forget: **when an answer has to be current to the second, the
right pipeline is often none.** The till already knows the stock, and a copy of it a second old
is only a second wrong about something the till could have said exactly. Pipelines are for
questions the source cannot answer, or should not be asked: across shops, across months, across
systems.

**Ponto Final's warehouse is fed by batch** for the rest of this course, and that is the common
case rather than the simple one. The streaming consumer comes back in lesson 3, where events are a
kind of source, and in lesson 15, where reading one twice has to do no harm.
