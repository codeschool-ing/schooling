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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three panels, one per measurement, each with the three runs before the change as dots on one line and the three runs after on the line below, on the same scale. Customer orders: before 0.836 to 0.857 milliseconds, after 0.794 to 0.800; the two groups do not overlap. Place order: before 8.156 to 8.794, after 8.212 to 8.357, inside the before. Overall rate: before 1134 to 1151, after 1116 to 1200, spread on both sides.\"><rect x=\"14\" y=\"20\" width=\"692\" height=\"84\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">customer-orders latency, ms</text><text x=\"692\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">apart: real</text><text x=\"28\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">before</text><path d=\"M150 60 L660 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M467.3333333333331 60 L586.3333333333333 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"3\"></path><circle cx=\"586.3333333333333\" cy=\"60\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"501.33333333333314\" cy=\"60\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"467.3333333333331\" cy=\"60\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"28\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">after</text><path d=\"M150 84 L660 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M229.33333333333343 84 L263.3333333333335 84\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></path><circle cx=\"240.6666666666668\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"229.33333333333343\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"263.3333333333335\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><rect x=\"14\" y=\"114\" width=\"692\" height=\"84\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">place-order latency, ms</text><text x=\"692\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">overlap: not shown</text><text x=\"28\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">before</text><path d=\"M150 154 L660 154\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M229.5600000000003 154 L554.9400000000003 154\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"3\"></path><circle cx=\"278.0099999999997\" cy=\"154\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"554.9400000000003\" cy=\"154\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"229.5600000000003\" cy=\"154\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"28\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">after</text><path d=\"M150 178 L660 178\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M258.1199999999999 178 L332.06999999999965 178\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></path><circle cx=\"332.06999999999965\" cy=\"178\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"319.3200000000004\" cy=\"178\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"258.1199999999999\" cy=\"178\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><rect x=\"14\" y=\"208\" width=\"692\" height=\"84\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">overall rate, a second</text><text x=\"692\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">overlap: not shown</text><text x=\"28\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">before</text><path d=\"M150 248 L660 248\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M307.6363636363636 248 L386.4545454545455 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"3\"></path><circle cx=\"372.5454545454545\" cy=\"248\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"307.6363636363636\" cy=\"248\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"386.4545454545455\" cy=\"248\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"28\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">after</text><path d=\"M150 272 L660 272\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224.1818181818182 272 L613.6363636363636 272\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></path><circle cx=\"613.6363636363636\" cy=\"272\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"224.1818181818182\" cy=\"272\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"381.8181818181818\" cy=\"272\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle></svg>", "caption": "Three runs before and three after, on one scale per measurement. Only the first pair of groups is apart."}
```

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
