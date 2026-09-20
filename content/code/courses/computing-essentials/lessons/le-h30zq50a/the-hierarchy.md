---
title: Five distances, and why every piece of advice is really about one of them
version: 1
---

Everything in this lesson so far has been about one idea approached from four sides, and this
section states it directly.

A processor does not have one place to get data from. It has five, they are arranged in order of
distance, and each step out is **not a little slower — it is an order of magnitude slower or
worse.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Five rows, nearest first, each with a bar whose length grows down the list. Registers, under one nanosecond. Cache, about five nanoseconds. Memory, about one hundred nanoseconds. A solid-state drive, about one hundred thousand nanoseconds. A hard disk, about ten million nanoseconds. A third column gives the same times on a human scale where one nanosecond is one second: one second, five seconds, two minutes, a day and a half, and four months. A note says the bars are nowhere near to scale and that at scale the last one would be four hundred metres long.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Where a processor can get a piece of data, nearest first — and what the wait is worth.</text><text x=\"14\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">where</text><text x=\"420\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it costs</text><text x=\"706\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">if one nanosecond were one second</text><text x=\"14\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">registers</text><rect x=\"108\" y=\"53\" width=\"6\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">under 1 ns</text><text x=\"706\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">one second</text><text x=\"14\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cache</text><rect x=\"108\" y=\"87\" width=\"16\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">about 5 ns</text><text x=\"706\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">five seconds</text><text x=\"14\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">memory</text><rect x=\"108\" y=\"121\" width=\"46\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">about 100 ns</text><text x=\"706\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--amber)\">two minutes</text><text x=\"14\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SSD</text><rect x=\"108\" y=\"155\" width=\"130\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">about 100 000 ns</text><text x=\"706\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--amber)\">a day and a half</text><text x=\"14\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hard disk</text><rect x=\"108\" y=\"189\" width=\"280\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">about 10 000 000 ns</text><text x=\"706\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--amber)\">four months</text><path d=\"M14 226 L706 226\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"14\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The bars are nowhere near to scale. At scale the last one would be four hundred metres long.</text></svg>", "caption": "The right-hand column is the one to keep. A processor waiting on a hard disk is a person waiting four months for an answer they needed in a second."}
```

The right-hand column is a standard trick and it is worth the paper it is printed on. Scale
every number so that **one nanosecond becomes one second**, which puts these distances on a
human clock:

- a register: **one second**
- cache: **five seconds**
- memory: **two minutes** — you would go and make tea
- an SSD: **a day and a half**
- a hard disk: **four months**

Those are not five points on a line. They are five different kinds of experience, and the whole
craft of making computers feel fast is keeping work in the top two.

## Cache is the one you have not met yet

The first two levels live inside the processor itself. **Registers** are the handful of values it
is operating on at this instant. **Cache** is a small, very fast copy of whatever memory it has
been using recently — typically a few megabytes, against gigabytes of RAM.

You do not manage cache and you cannot buy more of it separately. It is worth naming for one
reason: it is why two processors with the same clock speed and the same core count can differ by
a third in real work. One has more cache, so it reaches the two-minute level less often.

## What this explains, all at once

Every rule of thumb in this lesson is now the same rule:

| the advice | what it really says |
|---|---|
| close some tabs | stop the machine falling from *memory* to *SSD* |
| buy more RAM | same, and permanently |
| put an SSD in it | if you must fall, fall a day and a half and not four months |
| more cache is better | fall to memory less often |

**Nobody optimises a computer. They keep work from falling down a level.** That is the sentence
this lesson exists to hand over, and it is as true of a phone or a server as it is of the machine
in front of you.
