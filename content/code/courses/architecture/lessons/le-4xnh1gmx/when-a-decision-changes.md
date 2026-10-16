---
title: When a decision changes
version: 1
---

ADR 2 was right when it was written. Then traffic grew, the stock service made the whole shop slow twice
in a month, and the team built what lesson 9 built: the shop keeps a copy of the stock, fed by events.
The record of the old decision is **not edited**. A new record says what changed and why, and points at
the one it replaces:

`docs/adr/0005-keep-a-copy-of-the-stock.md`:

The decision that replaces ADR 2, the arrangement lesson 9 built: the shop listens instead of asking.

```
# 5. Keep a copy of the stock in the shop

Date: 2026-10-05

## Status

Accepted. Supersedes [2](0002-ask-the-stock-service-synchronously.md).

## Context

Product pages now make up most of the stock service's traffic, and a slow stock service made the whole
shop slow twice last month (lesson 12). Customers do not need the exact count on a product page; the
checkout does, and asks the stock service directly.

## Decision

The stock service publishes an event with the full count and a version whenever a count changes. The
shop keeps its own copy from those events, ignores any event older than the version it holds, and shows
"only a few left" rather than an exact number below ten.

## Consequences

Product pages no longer depend on the stock service being up. The number shown can be a few seconds
old, so the checkout keeps asking the stock service, as ADR 2 did for every page. The shop now runs a
consumer that must be monitored for lag.
```

The old record changes in exactly one line, its status, so that anybody who finds it is sent to the
decision now in force. Change it, and print the log again:

```
ana@vm:~/lab/adr$ sed -i 's/^Accepted$/Superseded by [5](0005-keep-a-copy-of-the-stock.md)./' docs/adr/0002-ask-the-stock-service-synchronously.md
ana@vm:~/lab/adr$ bash adr-index.sh
1. Record architecture decisions              Accepted
2. Ask the stock service synchronously        Superseded by [5](0005-keep-a-copy-of-the-stock.md).
3. Charge cards idempotently                  Accepted
4. No SELECT * in application code            Accepted
5. Keep a copy of the stock in the shop       Accepted. Supersedes [2](0002-ask-the-stock-service-synchronously.md).
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two records over time. ADR 2, accepted in March, decides that the shop asks the stock service on every page. In October ADR 5 is accepted and supersedes it. ADR 2 is not deleted or rewritten: only its status changes, to superseded by 5, and both remain in the log.\"><defs><marker id=\"l20-supersede-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"50\" width=\"280\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ADR 2: ask synchronously</text><text x=\"180\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">March: accepted</text><text x=\"180\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">October: superseded by 5</text><rect x=\"400\" y=\"50\" width=\"280\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ADR 5: keep a copy</text><text x=\"540\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">October: accepted</text><text x=\"540\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">supersedes 2</text><path d=\"M398 95 L322 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-supersede-ah-phosphor)\"></path><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">both stay in the log; neither is rewritten</text></svg>", "caption": "A changed decision is a new record. The old one stays, marked superseded, so the log tells the whole story of how the system got here."}
```

Both records stay. The log now says that the shop asked the stock service for seven months, why that was
right, what changed, and what was decided instead, and a reader who wonders "why not just call the stock
service?" finds that somebody did, and why it stopped. A log in which old decisions are rewritten to
match the present reads as if the system had always been designed this way, which is never true and
hides exactly the lessons a team paid for.
