---
title: Four things that change when the period never closes
version: 1
---

A stream processor reads events as they arrive and never reaches the end of its input. **Four
things a batch gets for free stop being free**, and almost every lesson in this course is about one
of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The same day of sales handled two ways. Above, a batch: sales collect all day and one job at two in the morning reads them all, so every answer is about yesterday. Below, a stream: each sale is handled seconds after it happens, and one sale from Natal arrives three hours and forty minutes late, after sales that happened later than it.\" data-fig=\"l1-batch-stream\"><defs><marker id=\"l1-batch-stream-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l1-batch-stream-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">batch</text><line x1=\"90\" y1=\"70\" x2=\"520\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"20\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stream</text><line x1=\"90\" y1=\"175\" x2=\"520\" y2=\"175\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><text x=\"520\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><text x=\"630\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">02:00</text><circle cx=\"110\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"160\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"185\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"215\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"245\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"300\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"330\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"360\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"395\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"440\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"470\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"500\" cy=\"70\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"305.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sales during the day</text><rect x=\"565\" y=\"48\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">one job at 02:00</text><text x=\"630\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads all of yesterday</text><path d=\"M 520 70 L 560 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l1-batch-stream-ah-8343)\"></path><circle cx=\"110\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"110\" y1=\"168\" x2=\"110\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"160\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"160\" y1=\"168\" x2=\"160\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"185\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"185\" y1=\"168\" x2=\"185\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"215\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"215\" y1=\"168\" x2=\"215\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"245\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"245\" y1=\"168\" x2=\"245\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"300\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"300\" y1=\"168\" x2=\"300\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"330\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"330\" y1=\"168\" x2=\"330\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"360\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"360\" y1=\"168\" x2=\"360\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"395\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"395\" y1=\"168\" x2=\"395\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"440\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"440\" y1=\"168\" x2=\"440\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"470\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"470\" y1=\"168\" x2=\"470\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"500\" cy=\"175\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"500\" y1=\"168\" x2=\"500\" y2=\"150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></line><circle cx=\"138\" cy=\"175\" r=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><circle cx=\"270\" cy=\"175\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"270\" y1=\"168\" x2=\"270\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><path d=\"M 141 184 Q 204 214 266 184\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l1-batch-stream-ah-83)\"></path><text x=\"204\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">late: happened 10:20, arrived 14:00</text><text x=\"305\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each sale handled seconds after it happens</text></svg>", "caption": "A batch waits for the period to close; a stream handles each event as it comes, including the one that comes late."}
```

## 1. There is no "everything"

A batch can say *total sales yesterday* because yesterday is over. A stream cannot say *total sales*
at all: the total is different a second later, and it never stops changing. Any aggregate over a
stream — a sum, a count, an average, a top ten — has to be asked over a slice of it, and **the
slice has to be chosen**. The slices are called **windows**: every five minutes, the last hour, one
customer's visit. Lesson 10 is about them.

## 2. Time has two meanings

In a batch, the sale's time and the time it was processed are hours apart and nobody cares, because
the job reads the whole day anyway. In a stream they are seconds apart, usually — and the exceptions
are where results go wrong. A till that loses its connection at 10:20 and gets it back at 14:00
sends its sales in a burst, and a processor that counts sales by the time they *arrived* puts two
hours of Natal's sales into the 14:00 minute. **Event time** is when it happened; **processing
time** is when the program saw it. Lessons 9 to 11 are about keeping them apart, and about deciding
how long to wait for the late ones.

## 3. Running it again is not free

A failed batch is rerun on the same input. A stream processor that crashes has already done part of
its work: some events were handled and written somewhere, others were not, and the program has to
know which. If it starts again too early in the stream it handles some events twice, and if it
starts too late it skips some. **What a crash costs is a decision**, and it has names — at most
once, at least once, exactly once — which lessons 7 and 8 take apart.

## 4. It never stops

A batch job runs for twenty minutes a night, and the rest of the time there is nothing to watch. A
stream runs all the time, and so does everything it needs: the brokers, the processors, the disks
that keep the history. **It has to be operated**: somebody has to notice when the processor falls
behind the events, which is called **lag**, and what to do when it does. And it has to be paid for
around the clock. Lessons 16 and 17 are about both.

## And one that does not change: order

There is a fifth question a batch answers by sorting, and a stream answers by how it stores
things: *in what order did these happen?* A withdrawal applied before the deposit it depends on
gives a different balance from the same two events the other way round. Kafka's answer is precise
and narrower than people expect — order is kept **per key, inside one partition**, and nowhere else
— and it is the subject of lessons 2 and 3.

None of the four makes streaming worse than batch. They make it a different kind of program, one
whose correctness has to be argued rather than assumed. The next section is about when that argument
is worth making.
