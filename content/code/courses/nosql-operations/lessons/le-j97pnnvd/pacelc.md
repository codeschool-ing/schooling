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
{"svg": "PLACEHOLDER-PACELC", "caption": "PLACEHOLDER"}
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
