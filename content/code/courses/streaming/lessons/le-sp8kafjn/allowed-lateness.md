---
title: Allowed lateness
version: 1
---

**Allowed lateness keeps a window's state for a while after the watermark has passed it, so a
late event can still update a result that was already emitted.** The watermark decides when a
window is first reported; lateness decides when it is forgotten. They are two settings because
they answer two questions: how long to wait before saying something, and how long to keep
listening after saying it.

With five minutes of lateness:

```
ubuntu@stream:~/work$ python watermark.py --lateness 5
```

Everything is the same until sale 8. The 09:05 window was emitted at sale 6 with two sales, as
before. When sale 8 arrives, the watermark is at 09:11:05 and the window's end plus five minutes is
09:15:00, so the window is still held. The sale is added and the program reports **a late update:
09:05 to 09:10 is now three sales and 21,380 cents**, the number lesson 10 got from the complete
list. Sale 11 is still dropped: its window ended at 09:05, plus five minutes is 09:10, and the
watermark had passed that long before.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of the watermark, from 09:05 to 09:16. The 09:05 to 09:10 window is open until the watermark reaches 09:10, when its result is emitted. With five minutes of allowed lateness it is kept until the watermark reaches 09:15, and a late sale arriving in that stretch updates it. After 09:15 the window is forgotten and a sale for it is too late.\" data-fig=\"l11-lifecycle\"><defs><marker id=\"l11-lifecycle-ah-4762\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window 09:05 to 09:10, lateness 5 minutes</text><rect x=\"40\" y=\"92\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">open: sales are counted</text><rect x=\"290\" y=\"92\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">emitted, still kept: a late sale updates it</text><rect x=\"540\" y=\"92\" width=\"130.0000000000001\" height=\"36\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"605.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">forgotten: too late</text><line x1=\"40\" y1=\"150\" x2=\"670.0000000000001\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l11-lifecycle-ah-4762)\"></line><line x1=\"40\" y1=\"147\" x2=\"40\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"40\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:05</text><line x1=\"90\" y1=\"147\" x2=\"90\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:06</text><line x1=\"140\" y1=\"147\" x2=\"140\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"140\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:07</text><line x1=\"190\" y1=\"147\" x2=\"190\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"190\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:08</text><line x1=\"240\" y1=\"147\" x2=\"240\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"240\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:09</text><line x1=\"290\" y1=\"147\" x2=\"290\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"290\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:10</text><line x1=\"340\" y1=\"147\" x2=\"340\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"340\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:11</text><line x1=\"390\" y1=\"147\" x2=\"390\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:12</text><line x1=\"440\" y1=\"147\" x2=\"440\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"440\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:13</text><line x1=\"490\" y1=\"147\" x2=\"490\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"490\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:14</text><line x1=\"540\" y1=\"147\" x2=\"540\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"540\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:15</text><line x1=\"590\" y1=\"147\" x2=\"590\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"590\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:16</text><text x=\"670.0000000000001\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">watermark</text><line x1=\"290\" y1=\"82\" x2=\"290\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"290\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">emit</text><line x1=\"540\" y1=\"82\" x2=\"540\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"540\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">forget</text></svg>", "caption": "The bound decides when a window is first emitted; the lateness decides when it is forgotten. In between, a late event is an update."}
```

## What a late update costs downstream

The processor now emits the 09:05 window twice, and that is the "emit on every update" of lesson
10, arriving through the side door. Whoever reads the output has to know it:

- A reader that **appends** each result as a new row now has two rows for 09:05, and a sum of the
  column counts sales 4 and 5 twice. An email that said "two sales" has gone and stays wrong.
- A reader that **upserts** by window replaces two with three, and the table is right. Lesson 8's
  idempotent writes are what make that safe to repeat.

So allowed lateness is not free for the reader, and the choice belongs to whoever owns both ends:
a dashboard that upserts can take hours of lateness; a feed of invoices that are sent once can take
none, and needs its late events handled some other way.

## What it costs the processor

Every window is kept for the lateness after the watermark passes it. With five-minute windows and
five minutes of lateness, one extra window per key is open at any moment; with an hour of
lateness, twelve. For five shops that is nothing. For per-customer sessions it is the difference
between a store that fits in memory and one that does not, the same arithmetic as lesson 10's keys
times windows.

## The names

In Flink, `allowedLateness(Duration)` on a window, separate from the watermark's bound. In Kafka
Streams the **grace period** does both jobs: a window accepts records until stream time passes its
end plus the grace, and emits updates as they come unless told to wait. In Spark the watermark's
delay is also the lateness, and the output mode decides whether updates are emitted, which lesson
12 shows. Different knobs, the same two questions.
