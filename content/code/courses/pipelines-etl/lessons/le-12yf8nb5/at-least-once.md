---
title: Exactly once is at least once, made harmless
version: 1
---

People ask for a pipeline that processes every record **exactly once**. No machine can promise that
when a network sits between two of them: a step that sends something and hears no answer cannot know
whether the other side received it. If it sends again, the record may arrive twice; if it does not,
it may never arrive. Lesson 10's price fetch is that situation, and its answer was to try again.

So real systems promise **at least once** — nothing is lost, and some things arrive more than once —
and make the duplicates harmless at the receiving end. That pair is what *exactly once* means in
practice:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l15-once\" aria-label=\"At least once plus idempotent writes. A sender retries until it hears an answer, so a record can arrive twice. The receiver writes by key, so the second copy changes nothing. The result is the same as if it had arrived once.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">sender</text><rect x=\"400.0\" y=\"70.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">receiver</text><path d=\"M150.0 84.0 L398.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"275.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">record 42</text><path d=\"M150.0 108.0 L398.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"275.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">record 42, again</text><text x=\"275.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry: no answer heard</text><path d=\"M550.0 95.0 L588.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"590.0\" y=\"70.0\" width=\"116.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the same row</text><text x=\"648.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">once</text><text x=\"475.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written by key</text></svg>", "caption": "Nothing is lost, and a duplicate costs nothing."}
```

The course has built every piece of it already:

- **Retries and clears** (lesson 10) make delivery at least once: a step that failed is run again
  until it works.
- **Idempotent loads** (this lesson) make the second run of a step leave what the first left.
- **Deduplication by an identifier** (lesson 6) does the same for records that arrive twice: the
  website's collector delivered some events more than once, and staging keeps one row per
  `event_id`, so a duplicate changes nothing.

The rule underneath is the course's spine, and it is short: **design every step as if it will be run
twice, because it will.** Then a retry is safe, a clear is safe, a backfill over loaded days is safe,
and moving a pipeline from one orchestrator to another — lesson 13 — changes how it is run and
nothing about what it produces.
