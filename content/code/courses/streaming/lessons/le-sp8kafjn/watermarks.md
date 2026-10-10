---
title: Watermarks
version: 1
---

**A watermark is a time W, carried along with the stream, that means: events with a time before W
are not expected any more.** When W passes the end of a window, the window is complete as far as
the processor will ever believe, and its result can be emitted.

The usual way to compute one is the simplest that could work, and it is the one Flink calls
bounded out-of-orderness:

```python
watermark = latest_event_time_seen - bound
```

The bound is how out of order the processor allows events to be. With a bound of two minutes, a
processor that has just seen a sale from 09:12:30 sets its watermark to 09:10:30, and that passes
the end of the 09:05 to 09:10 window, which is emitted. A sale that happened before 09:10:30 and
arrives after this moment is **late**: it is behind the watermark, and the processor has already
said that it did not expect it.

Two properties make it usable:

- **It only moves forward.** A sale from 09:08:50 arriving after one from 09:13:05 does not pull
  the watermark back, because the latest time seen is still 09:13:05. If it did move back, a
  window already emitted would be open again, and "emitted" would mean nothing.
- **It is made of event times.** Read the same topic tomorrow and the watermark passes 09:10 at the
  same record, so the same windows close with the same contents. Nothing about it depends on when
  the processor runs or how fast.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A chart with the twelve sales in arrival order across and event time up. Each sale is a dot; a stepped line two minutes below the highest dot so far is the watermark, and it never goes down. The two sales whose window had already been passed by the watermark when they arrived, 09:08:50 and 09:04:30, are marked as dropped. Horizontal lines at 09:05, 09:10, 09:15 and 09:20 are window ends, and each window is emitted at the arrival where the watermark first crosses its end.\" data-fig=\"l11-watermark\"><line x1=\"90\" y1=\"310\" x2=\"640\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"90\" y1=\"310\" x2=\"90\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82\" y=\"289.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><text x=\"82\" y=\"237.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:05</text><line x1=\"90\" y1=\"237.3\" x2=\"640\" y2=\"237.3\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"82\" y=\"185.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:10</text><line x1=\"90\" y1=\"185.4\" x2=\"640\" y2=\"185.4\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"82\" y=\"133.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:15</text><line x1=\"90\" y1=\"133.5\" x2=\"640\" y2=\"133.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"82\" y=\"81.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:20</text><line x1=\"90\" y1=\"81.5\" x2=\"640\" y2=\"81.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"646\" y=\"133.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">window ends</text><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">event time</text><text x=\"365.0\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sales in the order they arrived</text><text x=\"110.0\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"156.36363636363637\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"202.72727272727275\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"249.0909090909091\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"295.4545454545455\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"341.8181818181818\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"388.1818181818182\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"434.54545454545456\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><text x=\"480.90909090909093\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9</text><text x=\"527.2727272727273\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"573.6363636363636\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11</text><text x=\"620.0\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><path d=\"M 92.0 303.1 L 128.0 303.1 L 128.0 287.5 L 138.36363636363637 287.5 L 174.36363636363637 287.5 L 174.36363636363637 269.3 L 184.72727272727275 269.3 L 220.72727272727275 269.3 L 220.72727272727275 258.1 L 231.0909090909091 258.1 L 267.0909090909091 258.1 L 267.0909090909091 244.2 L 277.4545454545455 244.2 L 313.4545454545455 244.2 L 313.4545454545455 180.2 L 323.8181818181818 180.2 L 359.8181818181818 180.2 L 359.8181818181818 174.1 L 370.1818181818182 174.1 L 406.1818181818182 174.1 L 406.1818181818182 174.1 L 416.54545454545456 174.1 L 452.54545454545456 174.1 L 452.54545454545456 162.9 L 462.90909090909093 162.9 L 498.90909090909093 162.9 L 498.90909090909093 91.9 L 509.27272727272725 91.9 L 545.2727272727273 91.9 L 545.2727272727273 91.9 L 555.6363636363636 91.9 L 591.6363636363636 91.9 L 591.6363636363636 69.4 L 602.0 69.4 L 638.0 69.4\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"642.0\" y=\"69.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">watermark</text><circle cx=\"110.0\" cy=\"282.3\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"156.36363636363637\" cy=\"266.7\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"202.72727272727275\" cy=\"248.6\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"249.0909090909091\" cy=\"237.3\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"295.4545454545455\" cy=\"223.5\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"341.8181818181818\" cy=\"159.4\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"388.1818181818182\" cy=\"153.4\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"434.54545454545456\" cy=\"197.5\" r=\"4.5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"434.54545454545456\" y=\"212.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">dropped</text><circle cx=\"480.90909090909093\" cy=\"142.1\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"527.2727272727273\" cy=\"71.2\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"573.6363636363636\" cy=\"242.5\" r=\"4.5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"573.6363636363636\" y=\"257.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">dropped</text><circle cx=\"620.0\" cy=\"48.7\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle></svg>", "caption": "The watermark follows the latest event time two minutes behind and never moves back. A sale below it whose window has ended is late."}
```

## A heuristic, and the perfect kind

The bound is a guess about the stream, and the guess can be wrong in both directions. Too small,
and ordinary slow deliveries arrive behind the watermark and are treated as late. Too large, and
every window waits longer than it needed to, for events that were never coming. A watermark
computed this way is called **heuristic**, because it is an estimate.

A **perfect** watermark is possible only where the source knows its own order: a single till
writing to its own partition, in the order of its sales, with no buffering, could tell the
processor exactly how far it has got. Real systems combine many sources, buffer, and retry, so
almost every watermark in practice is a heuristic, and the right bound is a measurement, which is
the section on choosing it.

## Who carries it

In Flink the watermark is a special element that travels inside the stream, from the sources
through every operator, and an operator with several inputs forwards the lowest of their
watermarks. Spark Structured Streaming computes one watermark per query from the latest event time
seen, with the bound given by `withWatermark("at", "2 minutes")`, which lesson 12 uses. Kafka
Streams keeps a **stream time** per task, the highest timestamp seen, and its **grace period** is
the bound: a window accepts records until stream time passes its end plus the grace. Three
vocabularies, one idea: **the latest event time, minus a bound, moving only forward.**
