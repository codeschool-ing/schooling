---
title: At most once, at least once, exactly once
version: 1
---

**A delivery guarantee is a statement about one question: when a consumer crashes, what happens to
the record it was working on?** Every consumer of lessons 20 to 22 does two things per record, or per
batch: it does the work, such as adding a payment to a total, and it records that it has done it,
with a checkpoint in Kinesis or a committed offset in Kafka. A crash can land between the two, and
the order of the two decides the answer.

**Checkpoint first, then the work, is at most once.** If the process dies after the checkpoint and
before the work, the restart begins after a record that was never processed: it is lost, silently,
and nothing is ever done twice. **The work first, then the checkpoint, is at least once.** If the
process dies after the work and before the checkpoint, the restart reads the record again and does
the work a second time: nothing is lost, and some things are done twice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two orderings of the same two steps, with a crash between them. Top row, at most once: the consumer writes the checkpoint, crashes, and on restart begins after the record, so the record is never processed: lost. Bottom row, at least once: the consumer does the work, crashes before the checkpoint, and on restart reads the record again and does the work a second time: done twice.\" data-fig=\"l23-orders\"><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">at most once</text><rect x=\"150.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkpoint</text><line x1=\"262.0\" y1=\"50.0\" x2=\"290.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"296.0,50.0 290.0,47.0 290.0,53.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"298.0\" y=\"30.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"328.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crash</text><line x1=\"360.0\" y1=\"50.0\" x2=\"388.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"394.0,50.0 388.0,47.0 388.0,53.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"396.0\" y=\"30.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">work</text><text x=\"456.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never reached</text><line x1=\"518.0\" y1=\"50.0\" x2=\"546.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"552.0,50.0 546.0,47.0 546.0,53.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"554.0\" y=\"30.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">restart: after it</text><text x=\"629.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">lost</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">at least once</text><rect x=\"150.0\" y=\"130.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">work</text><line x1=\"262.0\" y1=\"150.0\" x2=\"290.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"296.0,150.0 290.0,147.0 290.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"298.0\" y=\"130.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"328.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crash</text><line x1=\"360.0\" y1=\"150.0\" x2=\"388.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"394.0,150.0 388.0,147.0 388.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"396.0\" y=\"130.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checkpoint</text><text x=\"456.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never reached</text><line x1=\"518.0\" y1=\"150.0\" x2=\"546.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"552.0,150.0 546.0,147.0 546.0,153.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"554.0\" y=\"130.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">restart: read again</text><text x=\"629.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">done twice</text></svg>", "caption": "The order of the work and the checkpoint decides what a crash between them does."}
```

**Exactly once is not a third ordering.** There is no way to arrange the two steps so that a crash
between them neither loses nor repeats, because the work happens in one system, DynamoDB or S3 or a
bank, and the checkpoint in another, and no single write covers both. Exactly once is a property of
the whole pipeline, built in one of two ways: either the work and the checkpoint are made one atomic
write, which is what Kafka's transactions do inside Kafka. Or the work is made **idempotent**, so that
doing it twice leaves the same result as doing it once. Then at-least-once delivery produces
exactly-once effects, and that is the guarantee this lesson builds.

## What each service promises

| | promises | so the consumer must |
|---|---|---|
| Kinesis Data Streams | at least once: AWS documents that records can be delivered more than once | tolerate duplicates |
| Data Firehose | at least once into S3: a retried delivery can write a record twice | tolerate duplicates in the lake |
| Lambda reading Kinesis | at least once: a failed batch is retried whole | make the function idempotent |
| Kafka, default settings | at least once | tolerate duplicates, or use transactions |

**At least once is the default everywhere, because it is the only one that loses nothing.** At most
once is a choice to make only for data that may be lost, such as metrics a later sample replaces.
Everything Quitanda counts, payments above all, is at least once. So every consumer of it has to answer the next section's question: where do the duplicates come from, and how is one told
apart from a second, real event that happens to look the same?
