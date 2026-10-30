---
title: At most once, at least once, exactly once
version: 1
---

**A delivery guarantee answers one question: when a consumer dies, what happens to the message it was
working on?** Every consumer of Pub/Sub does two things with a message. It does the work, such as
adding a payment to a customer's total, and it acknowledges the message, which tells Pub/Sub not to
deliver it again. A crash can land between the two, and the order of the two decides the answer.

**Ack first, then the work, is at most once.** If the process dies after the ack and before the work,
Pub/Sub has already forgotten the message and the work never happens: the message is lost, in
silence, and nothing is ever done twice. **The work first, then the ack, is at least once.** If the
process dies after the work and before the ack, the ack deadline runs out, the message is delivered
again, and the work is done a second time: nothing is lost, and some things are done twice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two orderings of the same two steps, with a crash between them. Top row, at most once: the consumer acks the message, crashes, and the work is never reached; Pub/Sub does not deliver the message again, so it is lost. Bottom row, at least once: the consumer does the work, crashes before the ack, and the message is delivered again after its deadline, so the work is done twice.\" data-fig=\"l20-orders\"><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">at most once</text><rect x=\"150.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ack</text><line x1=\"262.0\" y1=\"50.0\" x2=\"290.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"296.0,50.0 290.0,53.0 290.0,47.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"298.0\" y=\"30.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"328.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crash</text><line x1=\"360.0\" y1=\"50.0\" x2=\"388.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"394.0,50.0 388.0,53.0 388.0,47.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"396.0\" y=\"30.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">work</text><text x=\"456.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never reached</text><line x1=\"518.0\" y1=\"50.0\" x2=\"546.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"552.0,50.0 546.0,53.0 546.0,47.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"554.0\" y=\"30.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restart: not delivered again</text><text x=\"629.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">lost</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">at least once</text><rect x=\"150.0\" y=\"130.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">work</text><line x1=\"262.0\" y1=\"150.0\" x2=\"290.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"296.0,150.0 290.0,153.0 290.0,147.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"298.0\" y=\"130.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"328.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">crash</text><line x1=\"360.0\" y1=\"150.0\" x2=\"388.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"394.0,150.0 388.0,153.0 388.0,147.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"396.0\" y=\"130.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ack</text><text x=\"456.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never reached</text><line x1=\"518.0\" y1=\"150.0\" x2=\"546.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"552.0,150.0 546.0,153.0 546.0,147.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"554.0\" y=\"130.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restart: delivered again</text><text x=\"629.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">done twice</text></svg>", "caption": "The order of the work and the ack decides what a crash between them does."}
```

**Exactly once is not a third ordering.** No arrangement of the two steps survives a crash between
them, because the work lands in one system, a database or a bucket or a bank, and the ack in
another, Pub/Sub, and no single write covers both. Exactly once is a property of the whole pipeline,
built in one of two ways. Either the work and the record of having done it become one atomic write
in the same system, or the work is made **idempotent**, so that doing it twice leaves the same result
as doing it once. Then at-least-once delivery produces exactly-once effects, and that is what this
lesson builds.

## The ack is per message, and there is no position

**Pub/Sub keeps no offset for a consumer to write down.** A log such as a Kafka partition keeps its
messages in a line, and a consumer records how far along the line it has got: one number, written
every so often, and everything after it is read again after a crash. A subscription has no line. Each
message is acknowledged on its own, in any order, and Pub/Sub keeps track of which ones are still
out. That makes the unit of a duplicate one message rather than a stretch of the log: what comes back
after a crash is exactly the messages that were pulled and not acked, and nothing that was acked
before them. It also means there is no position to rewind to by hand. Reading again is a `seek`, to a
time or to a snapshot, the tool of lesson 19, and this lesson's third section uses it.

## What Pub/Sub promises

| delivery | promises | so the consumer must |
|---|---|---|
| pull, unary or streaming | at least once: a message not acked in time is delivered again | tolerate duplicates |
| push | at least once: any answer but a 2xx, or none in time, is a nack | make the endpoint idempotent |
| ordered subscription | at least once, and a redelivery brings back the key's later messages too | tolerate duplicates, in order |
| pull with exactly-once delivery | no redelivery after a successful ack, nor while a deadline holds | still tolerate the publisher's duplicates |

The last row is the subject of this lesson's last section, and its last column is the reason it is
not the end of the story. **At least once is the default because it is the one that loses nothing.**
Duplicates can be removed afterwards; a message acked before its work was done is gone for good. At
most once suits only data that may be lost, such as a metric the next sample replaces. Everything
Quitanda counts, payments first, is consumed at least once. So every consumer of it has to answer the
next section's question: where do the duplicates come from, and how is one told apart from a
second, real event that happens to look the same?
