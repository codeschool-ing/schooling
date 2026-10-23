---
title: Tracing a requirement to its decision and its test
version: 1
---

**Traceability is the ability to follow a requirement forward to the decisions and code that meet
it, and to the test that proves it, and backward from any decision to the requirement it serves.**
It sounds like bureaucracy and is mostly a habit: give everything an id, and write the ids down where
the next thing refers to them.

## A chain, end to end

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l06-trace\" aria-label=\"A traceability chain for offline boarding, four boxes joined left to right by their ids: the requirement QS-02, the decision record ADR-0006, the model elements boarding app and boarding sync, and the offline scan test.\"><defs><marker id=\"l06-trace-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><text x=\"95.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">requirement</text><rect x=\"15.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">QS-02</text><text x=\"95.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">offline scan, 1 s</text><text x=\"275.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">decision</text><rect x=\"195.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ADR-0006</text><text x=\"275.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">ticket list on the phone</text><text x=\"455.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">model</text><rect x=\"375.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boarding app, sync</text><text x=\"455.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">deployment view</text><text x=\"635.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">verification</text><rect x=\"555.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">offline scan test</text><text x=\"635.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">every release</text><path d=\"M175.0 80.0 L195.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-trace-am-fill-paper)\"></path><path d=\"M355.0 80.0 L375.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-trace-am-fill-paper)\"></path><path d=\"M535.0 80.0 L555.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-trace-am-fill-paper)\"></path><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each link is a reference by id, so a renamed title breaks nothing</text></svg>", "caption": "Forward from the requirement to its proof, and backward from any test to the reason it exists."}
```

For offline boarding the chain at Carcará is:

1. **QS-02** in the requirements: scans accepted or refused within a second with no signal.
2. **ADR-0006** in the decision log: *each phone keeps the trip's ticket list*, with the 15-minute
   sync and the stale-ticket rule among its consequences.
3. **The boarding sync service** and the **local store** on the deployment diagram, each labelled
   with ADR-0006 in its description.
4. **A test** that runs the boarding app with the network switched off and scans 200 tickets,
   failing if any check takes more than a second.

Each link is just a reference by id. **The ids are what make the chain survive renaming**: lesson 1
of this course and the platform's own rules make the same point about joining things by stable ids
rather than by titles.

## The matrix, and when to keep one

A traceability matrix puts requirements in rows and the things that satisfy them in columns. For a
regulated domain, such as medical devices, aviation or some public contracts, it is required. For
Carcará, a small table in the architecture document is enough, and it covers only the significant
requirements:

| requirement | decisions | where in the model | verified by |
| --- | --- | --- | --- |
| QS-01 peak purchases | ADR-0009, ADR-0012 | ticketing API, seat-hold store | load test before every São João |
| QS-02 offline boarding | ADR-0006 | boarding app, boarding sync | offline scan test, every release |
| QS-03 database failover | ADR-0002 | booking database | failover drill, every quarter |
| QS-04 new payment method | ADR-0011 | payment adapter, `PaymentPort` | the last method took 7 days |
| QS-05 refund audit | ADR-0015 | audit log | quarterly audit sample |

## Reading a matrix for gaps

The matrix is useful mainly for what it does not have:

- **a requirement with no decision** is one nobody has designed for yet;
- **a decision with no requirement** is either serving a requirement nobody wrote down, which should
  be written, or serving none, which makes it a candidate for removal;
- **a requirement with no verification** is a hope. *The last method took 7 days* is weak evidence,
  but it is evidence; an empty cell is none.

Lesson 11 returns to verification as **fitness functions**, automated checks that keep a quality
true as the system changes, and lesson 13 uses this table as the starting point of a review.
