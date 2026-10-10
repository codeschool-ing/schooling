---
title: PACELC, the price you pay when nothing is broken
version: 1
---

CAP describes a bad afternoon. **PACELC describes every other afternoon**, and for most systems
that is where the cost of consistency is actually paid.

The name is a sentence. Daniel Abadi wrote it down in 2010 and published it in 2012: **if there is a
Partition, choose between Availability and Consistency; Else, choose between Latency and
Consistency.** The first half is CAP. The second half is the observation CAP leaves out: even with
a perfect network, keeping copies in agreement costs time on every write, and a system has to decide
whether to pay it.

## Where the time goes

A write is only consistent across copies once the other copies have it. So a system that promises
"once you are told it succeeded, every copy agrees" has to wait for the other copies to answer
before it tells you anything. That wait is at least one network round trip to the slowest copy it
waits for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"A timeline of one write. On the left, the copy in São Paulo answers the client as soon as it has the write, and sends it to Lisbon afterwards. On the right, the copy in São Paulo first sends the write to Lisbon, waits for Lisbon to acknowledge it, and only then answers the client, at least one round trip later.\"><defs><marker id=\"pac1-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pac1-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pac1-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">else latency: answer at once</text><text x=\"50\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">client</text><line x1=\"50\" y1=\"52\" x2=\"50\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"170\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><line x1=\"170\" y1=\"52\" x2=\"170\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Lisbon</text><line x1=\"300\" y1=\"52\" x2=\"300\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"50\" y1=\"70\" x2=\"168\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"110.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">write</text><line x1=\"170\" y1=\"95\" x2=\"52\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"110.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text><line x1=\"170\" y1=\"120\" x2=\"298\" y2=\"165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-paper-dim)\" stroke-dasharray=\"4 3\"></line><text x=\"260\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">arrives later</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">else consistency: wait for Lisbon</text><text x=\"400\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">client</text><line x1=\"400\" y1=\"52\" x2=\"400\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"520\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><line x1=\"520\" y1=\"52\" x2=\"520\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"650\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Lisbon</text><line x1=\"650\" y1=\"52\" x2=\"650\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"400\" y1=\"70\" x2=\"518\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"460.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">write</text><line x1=\"520\" y1=\"90\" x2=\"648\" y2=\"135\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-amber)\"></line><line x1=\"650\" y1=\"145\" x2=\"522\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-amber)\"></line><text x=\"593.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">≥ 80 ms</text><text x=\"593.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">there and back</text><line x1=\"520\" y1=\"205\" x2=\"402\" y2=\"220\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"460.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text></svg>", "caption": "The same write, answered two ways. Waiting for the far copy is what makes every copy agree, and it costs at least one round trip on every write."}
```

Put numbers on the shop. São Paulo and Lisbon are about 7,900 km apart. Light in an optical fibre
covers about 200,000 km a second, so a message there and back cannot take less than about 80 ms,
before any switch, router or busy server adds its share. A write that waits for Lisbon's
acknowledgement costs every customer in São Paulo at least that, on every single write. A write
that answers as soon as São Paulo has it costs a millisecond or two, and Lisbon catches up a moment
later.

That is the second choice:

- **Else Consistency (EC):** wait for the other copies. Every write is slower, and a read anywhere
  sees it.
- **Else Latency (EL):** answer at once and replicate in the background. Every write is fast, and
  for a short window a read from another copy can return the older value.

The window in the second case is usually milliseconds. It is not zero, and an application that
assumes it is zero has a bug that shows up only under load, only sometimes, and never on the
developer's laptop, where every copy is on one machine. Lesson 5 is about what an application has to
do to live with that window.

## Four letters for a system, and why they describe a setting

PACELC classifies a system by its two choices together. A system that refuses during a partition
and waits for copies otherwise is **PC/EC**; one that answers during a partition and does not wait
otherwise is **PA/EL**. Those two are the common pairs, because a system that is willing to pay
latency every day usually also refuses rather than diverge on the bad day.

The trap is to read the letters as a property of a product. All three products in this course let
you change the answer, and the next section is about doing it on purpose.
