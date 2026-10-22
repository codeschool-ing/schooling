---
title: What volatile guarantees
version: 1
---

**`volatile` makes two promises, and the second is the one that makes it useful beyond a single flag.**

1. **Visibility.** A read of a `volatile` field sees the most recent write to it, by any thread.
2. **Ordering.** A write to a `volatile` field happens-before every later read of it (lesson 12
   section 04). Everything the writing thread did *before* the write is therefore visible to the reading
   thread *after* the read, including ordinary fields.

The second promise turns one `volatile` field into a gate for any amount of ordinary data. A producer
fills in plain fields, then sets a `volatile` flag; a consumer waits for the flag, then reads the plain
fields and is guaranteed to see them complete:

```schooling-example
{
  "language": "java",
  "file": "Handoff.java",
  "parts": [
    {
      "code": "// Handoff.java: ordinary fields published by one volatile write\npublic class Handoff {\n    static String title;\n    static long priceCents;\n    static int copies;\n    static volatile boolean ready;",
      "note": "Three ordinary fields, and one `volatile` flag that guards them."
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        Thread consumer = new Thread(() -> {\n            while (!ready) {\n                Thread.onSpinWait();\n            }\n            System.out.println(title + \", \" + copies + \" copies at \" + priceCents);\n        });\n        consumer.start();",
      "note": "The consumer reads the flag until it is `true`. `Thread.onSpinWait()` tells the processor this is a busy-wait, which some processors use to save power; it creates no ordering of its own."
    },
    {
      "code": "\n        title = \"Middlemarch\";\n        priceCents = 4490;\n        copies = 3;\n        ready = true;\n        consumer.join();\n    }\n}\n",
      "note": "The producer writes the data first and the flag last. The order matters: a write placed after `ready = true` would not be covered by the promise."
    }
  ],
  "output": "Middlemarch, 3 copies at 4490"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Producer and consumer timelines. The producer writes title, priceCents and copies, then the volatile write ready = true. The consumer's volatile read of ready returns true, and after it come the plain reads of the three fields. An arrow from the volatile write to the volatile read carries everything written before it.\"><defs><marker id=\"gate-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"gate-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">producer</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">consumer</text><rect x=\"110\" y=\"20\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">title = ...; priceCents = ...; copies = 3;</text><rect x=\"450\" y=\"20\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ready = true</text><rect x=\"330\" y=\"140\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">while (!ready)</text><rect x=\"510\" y=\"140\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reads the three fields</text><path d=\"M410 40 L446 40\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gate-ah-paperdim)\"></path><path d=\"M480 160 L506 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gate-ah-paperdim)\"></path><path d=\"M525 60 L430 136\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#gate-ah-phosphor)\"></path><text x=\"560\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">volatile write, then read</text></svg>", "caption": "Everything written before the volatile write is visible after the volatile read that sees it."}
```

## The order of the writes is the whole trick

The consumer printed the three values, all of them, because the three plain writes came **before** the
`volatile` write in the producer's program order, and the consumer's plain reads came **after** its
`volatile` read. Program order on each side, plus the edge between the two `volatile` accesses, orders
everything. Move `ready = true` above `copies = 3` and the consumer may see `ready` and still read
`copies` as 0: nothing then orders that last write before the read.

This is what `volatile` buys in practice: **a way for one thread to hand a complete piece of work to
another without a lock**, as long as the work is finished before the flag goes up and nobody changes it
afterwards. Lesson 15's queues and lesson 16's futures do the same handover with the edges built in, and
are what you should reach for first; knowing that they work this way underneath is what makes their
guarantees believable.
