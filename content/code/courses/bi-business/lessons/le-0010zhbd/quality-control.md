---
title: Quality control: the defect, the yield and the signal
version: 1
---

A packaging factory sells to customers who fill its pots with yoghurt and screw its caps onto
bottles on lines that run at hundreds a minute. A cap that does not seal stops their line, or worse,
reaches a supermarket shelf. **Quality indicators answer two questions: how many bad parts did we
make, and is the process making more of them than it should?** The first is counting. The second is
the more useful idea, and it is where a control chart comes in.

## Counting bad parts three ways

The **scrap rate**, or defect rate, is bad parts over parts made. IM-07's second shift made 1,350
caps and 54 were scrapped, which is 4.0%, the other side of the 96.0% quality factor in OEE.

Customers count in **parts per million**, ppm, because the rates they care about are too small for
percentages. One customer received 2,400,000 Serra Azul caps in October 2025 and returned 312 as
defective:

```localised
=ROUND(312/2400000*1000000,0)      130
```

**130 ppm is 0.013%**: written as a percentage, it looks like nothing, and written as ppm it is a
number a contract can set a limit on. The same shift's 54 scrapped caps out of 1,350 would be 40,000
ppm, which shows why scrap inside the plant and defects reaching a customer are reported on
different scales.

**First-pass yield** asks a narrower question: of the parts made, how many were good the first time,
with no rework? Of IM-07's 1,296 good caps, 27 had a thin rim of excess plastic, called flash,
trimmed off by hand before they were boxed:

```localised
=ROUND((1296-27)/1350*100,1)      94
```

Quality said 96.0%; first-pass yield says 94.0%. The difference is 27 caps that were good only
because somebody spent time on them, and that time appears in no other number.

## A value out of line, or a signal?

Every process varies. IM-07's scrap rate was 1.9% one day and 2.3% the next, with nothing changed.
**The wrong reaction is to treat every high day as a problem**: adjust the settings after a bad day,
and the next day's ordinary variation is now on top of an adjustment nobody needed.

A control chart separates the two. Its limits are computed from a period when the process was known
to be stable. In September, 25 days with no changes to IM-07 gave a mean scrap rate of 2.0%, and
**control limits at the mean plus and minus three standard deviations**: 0.8% and 3.2%. How the
standard deviation is computed and why three is `statistics` lessons 5 and 8; here the limits are
given. Type November's 12 working days:

| | A | B |
|---|---|---|
| 1 | Day | Scrap % |
| 2 | 1 | 1.9 |
| 3 | 2 | 2.3 |
| 4 | 3 | 1.6 |
| 5 | 4 | 2.1 |
| 6 | 5 | 2.8 |
| 7 | 6 | 1.7 |
| 8 | 7 | 2 |
| 9 | 8 | 2.4 |
| 10 | 9 | 3.6 |
| 11 | 10 | 2.2 |
| 12 | 11 | 1.8 |
| 13 | 12 | 3 |

In B16 type the upper limit, 3.2, and test two days against it:

```localised
=IF(B10>B16,"outside","inside")      outside
=IF(B13>B16,"outside","inside")      inside
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A control chart of IM-07's daily scrap rate over 12 working days of November 2025. A centre line at 2.0% and control limits at 0.8% and 3.2%, from a stable period in September. Eleven days fall inside the limits, including day 12 at 3.0%. Day 9, at 3.6%, is above the upper limit.\" data-fig=\"l20-control-chart\"><path d=\"M70.0 260.0 L590.0 260.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0%</text><path d=\"M70.0 205.0 L590.0 205.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"209.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0%</text><path d=\"M70.0 150.0 L590.0 150.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"154.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2.0%</text><path d=\"M70.0 95.0 L590.0 95.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"99.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3.0%</text><path d=\"M70.0 40.0 L590.0 40.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4.0%</text><path d=\"M70.0 84.0 L590.0 84.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><path d=\"M70.0 216.0 L590.0 216.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><path d=\"M70.0 150.0 L590.0 150.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"598.0\" y=\"88.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">upper limit 3.2%</text><text x=\"598.0\" y=\"154.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">centre 2.0%</text><text x=\"598.0\" y=\"220.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lower limit 0.8%</text><path d=\"M90.0 155.5 L133.6 133.5 L177.3 172.0 L220.9 144.5 L264.5 106.0 L308.2 166.5 L351.8 150.0 L395.5 128.0 L439.1 62.0 L482.7 139.0 L526.4 161.0 L570.0 95.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M86.0 151.5 H94.0 V159.5 H86.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M129.6 129.5 H137.6 V137.5 H129.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"133.6\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M173.3 168.0 H181.3 V176.0 H173.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"177.3\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M216.9 140.5 H224.9 V148.5 H216.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"220.9\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M260.5 102.0 H268.5 V110.0 H260.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"264.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M304.2 162.5 H312.2 V170.5 H304.2 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"308.2\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><path d=\"M347.8 146.0 H355.8 V154.0 H347.8 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"351.8\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><path d=\"M391.5 124.0 H399.5 V132.0 H391.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"395.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M435.1 58.0 H443.1 V66.0 H435.1 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"439.1\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><path d=\"M478.7 135.0 H486.7 V143.0 H478.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"482.7\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M522.4 157.0 H530.4 V165.0 H522.4 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"526.4\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><path d=\"M566.0 91.0 H574.0 V99.0 H566.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"570.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"330.0\" y=\"300.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">working day of November 2025</text><text x=\"449.1\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">day 9: 3.6%, look for a cause</text></svg>", "caption": "Day 9 is a signal: it falls outside limits computed from a period when the process was stable. Day 12 is higher than ten of the other days and still inside them, which makes it part of the ordinary variation."}
```

**Day 9 is a signal**: a value that ordinary variation would very rarely produce, which is worth
looking for a cause. Rafael found one: a new lot of resin from a different supplier had been loaded
that morning. **Day 12 is not a signal**, though it is the second-highest day of the month and a
whole point above the centre. Inside the limits, the chart says, 3.0% is what this process does
sometimes, and stopping the line to adjust it would add variation instead of removing it.

The limits are not targets, and they are not the customer's specification. A process can be stable
and still make too many bad parts for the customer, in which case the process has to change; and it
can be inside the customer's limits while the chart signals that something just moved. The chart
answers one question only: has the process changed?
