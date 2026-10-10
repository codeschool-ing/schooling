---
title: Bigger than the noise, or not
version: 1
---

A difference between two numbers is a finding only if it is larger than the difference between two
measurements of the **same** thing. That second difference is the noise, and the before-and-after
section measured it without trying: three runs of an unchanged database are three different
numbers.

## The three statements, three ways

Lay each script's three runs out as a range, before and after:

| | before | after | ranges overlap? |
|---|---|---|---|
| customer-orders latency | 0.836 – 0.857 ms | 0.794 – 0.800 ms | no |
| place-order latency | 8.156 – 8.794 ms | 8.212 – 8.357 ms | yes, entirely |
| overall rate | 1134 – 1151 a second | 1116 – 1200 a second | yes, entirely |

Three readings, three verdicts.

**The customer's order list really did get faster.** Its worst after is better than its best
before, and the gap between the two ranges, about 0.04 milliseconds, is larger than the spread
inside either. The server's own mean, from 0.107 to 0.089, agrees. That is as close to proof as three
runs give.

**The writes cannot see the new index.** The before spans 0.64 milliseconds, from 8.156 to 8.794, and
the after sits inside it. If the index made each purchase slower, the difference is smaller than
the noise of a thirty-second run, and these numbers cannot say which way it went. That is not the
same as "it cost nothing": it means **this measurement is too coarse** to show it. The next section
measures the cost a different way.

**The overall rate moved by nothing you can name.** One after-run was the fastest of all six and
another the slowest. A change to a statement that takes under a millisecond, in a workload whose
time goes to the tag search and the pending count, disappears in the variation between one
thirty-second run and the next.

## A rule you can apply without statistics

A proper test of significance is the right tool when a lot depends on the answer, and it needs more
runs than three. For an everyday decision, a rule that is crude and still honest:

- run the before **at least three times**, under the same conditions as the after;
- call the change real **only if the ranges do not overlap**;
- if they overlap, the answer is "not shown", and a longer run or more runs is the way to find out —
  never the run that happened to look best.

The trap the rule closes is the most common one in performance work: one before, one after, a
difference of a few percent, and a conclusion. In this lesson's own data, picking the before-run
of 1134 and the after-run of 1200 makes the change look like **6% more throughput**; picking 1151 and
1116 makes it look like a loss. Both are the same database, measured honestly, and both are wrong.
