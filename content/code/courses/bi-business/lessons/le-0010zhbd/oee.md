---
title: OEE: one shift taken apart
version: 1
---

Serra Azul Embalagens makes plastic caps, lids and pots in Joinville, Santa Catarina, on 14
injection-moulding machines that run three shifts a day. It is invented, like every organisation in
this course. Its process engineer, Rafael Hoffmann, also builds its reports, and the questions he
gets fall under lesson 17's four like this:

| lesson 17's question | in a factory |
|---|---|
| the decisions made over and over | which machine makes which order, when to stop a machine for maintenance, whether a batch of parts can ship, how many people each shift needs |
| the indicators that serve them | OEE and its three factors; MTBF, MTTR and availability; scrap rate, parts per million, first-pass yield; a control chart |
| the data, and what is odd about it | machines record every cycle to the second, the ERP records orders and boxes, and **people record scrap by hand at the end of the shift**: three records of one event, with three clocks |
| the typical trap | trusting the number that a person typed, because it sits in the same table as the ones a machine counted |

## The wrong question: was the machine running?

A machine that is switched on all shift looks fully used. Rafael's first report, years ago, said
exactly that: IM-07 ran for the whole of the second shift. It did not say that it stopped twice,
ran slower than it should when it ran, and made parts that went in the scrap bin. **OEE, overall
equipment effectiveness, is the standard way of counting all three losses in one number**:

OEE = availability × performance × quality

Each factor answers one question about the time the machine was supposed to be making parts.

## One shift, typed

IM-07, second shift, Tuesday 11 November 2025, 14:00 to 22:00. The mould makes one cap every 15
seconds at its rated speed. Type the shift into a new sheet:

| | A | B |
|---|---|---|
| 1 | Shift length (min) | 480 |
| 2 | Planned stops (min) | 30 |
| 3 | Unplanned stops (min) | 63 |
| 4 | Ideal cycle (s per part) | 15 |
| 5 | Parts made | 1350 |
| 6 | Good parts | 1296 |

The 30 planned minutes are the team's break, and they are not a loss: the machine was never meant to
run then. The 63 unplanned minutes are a mould change that took 35 and a breakdown that took 28.

**Availability** is the share of the planned time the machine actually ran:

```localised
=B1-B2      450
=B1-B2-B3      387
=ROUND((B1-B2-B3)/(B1-B2)*100,1)      86
```

**Performance** is how many parts it made against how many it could have made in the time it ran,
at the ideal cycle. The cycle is in seconds and the time in minutes, hence the 60:

```localised
=ROUND(B4*B5/((B1-B2-B3)*60)*100,1)      87.2
```

**Quality** is the share of the parts that were good:

```localised
=ROUND(B6/B5*100,1)      96
```

Multiply the three and the shift's OEE is **72.0%**. There is a shorter route to the same number,
and it is a useful check: the time it would have taken to make only the good parts at the ideal
cycle, over the planned time.

```localised
=ROUND(B4*B6/((B1-B2)*60)*100,1)      72
```

## Where the minutes went

OEE's value is not the 72; it is the split. Of the 450 planned minutes, 324 went into good parts.
The other 126 are losses, and each has an owner:

| loss | minutes | where it shows | who acts |
|---|---|---|---|
| stops | 63 | availability, 86.0% | maintenance, and whoever plans mould changes |
| slow cycles | 49.5 | performance, 87.2% | process engineering: settings, material, the mould |
| scrap | 13.5 | quality, 96.0% | quality and the operators |

**The biggest loss here is stops, and the least visible is speed.** Nobody on the floor sees a
machine running at 17 seconds a cycle instead of 15; the machine is running, the light is green, and
49.5 minutes disappear across the shift in two seconds at a time. The 1,350 parts against the 1,548
the running time allowed at full speed is the only place they show.

## The screen at the end of a shift

At 22:00 the second shift hands over to the third, and the supervisor coming in needs the answer to
lesson 14's question before anything else: what needs my attention now?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"A mock of the shift supervisor's screen at Serra Azul, at the end of the second shift, 22:00 on Tuesday 11 November 2025. Shift OEE 77.1%. Fourteen machine tiles, stopped machines first: IM-11 down for a breakdown for 18 minutes; IM-03 in a mould change; then the twelve running machines, each with its OEE this shift. Below, IM-07's shift split into availability, performance and quality.\" data-fig=\"l20-shift-screen\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"400.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Moulding hall · shift 2</text><text x=\"692.0\" y=\"34.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tue 11 Nov 2025, 22:00</text><text x=\"692.0\" y=\"50.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">machine counters, every minute</text><text x=\"28.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">shift OEE: 77.1%</text><rect x=\"28.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"36.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-11</text><text x=\"36.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">down 18 min</text><rect x=\"124.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"132.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-03</text><text x=\"132.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">mould change</text><rect x=\"220.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-07</text><text x=\"228.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">72.0%</text><rect x=\"316.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-13</text><text x=\"324.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">73.7%</text><rect x=\"412.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"420.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-09</text><text x=\"420.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">74.1%</text><rect x=\"508.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"516.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-02</text><text x=\"516.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">76.8%</text><rect x=\"604.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"612.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-05</text><text x=\"612.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">77.5%</text><rect x=\"28.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-06</text><text x=\"36.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">80.4%</text><rect x=\"124.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"132.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-10</text><text x=\"132.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">82.0%</text><rect x=\"220.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-12</text><text x=\"228.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">82.9%</text><rect x=\"316.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-01</text><text x=\"324.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">83.8%</text><rect x=\"412.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"420.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-14</text><text x=\"420.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">85.7%</text><rect x=\"508.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"516.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-04</text><text x=\"516.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">86.5%</text><rect x=\"604.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"612.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-08</text><text x=\"612.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">88.4%</text><text x=\"28.0\" y=\"260.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">IM-07 this shift: where the minutes went</text><text x=\"28.0\" y=\"296.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">availability</text><path d=\"M150.0 282.0 H450.0 V300.0 H150.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M150.0 282.0 H408.0 V300.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"460.0\" y=\"296.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">86.0%</text><text x=\"520.0\" y=\"296.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">stops: mould change, breakdown</text><text x=\"28.0\" y=\"326.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">performance</text><path d=\"M150.0 312.0 H450.0 V330.0 H150.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M150.0 312.0 H411.6 V330.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"460.0\" y=\"326.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">87.2%</text><text x=\"520.0\" y=\"326.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">slower than the 15 s cycle</text><text x=\"28.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quality</text><path d=\"M150.0 342.0 H450.0 V360.0 H150.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M150.0 342.0 H438.0 V360.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"460.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">96.0%</text><text x=\"520.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">parts scrapped</text><text x=\"28.0\" y=\"396.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">OEE = availability × performance × quality</text></svg>", "caption": "The supervisor's screen starts with the machines that are not making parts, then shows every other machine's OEE, and splits one machine's shift into the three losses so the supervisor knows which kind of problem to walk over to."}
```

The two machines that are not making parts come first, whatever their OEE. The running ones show
their OEE for the shift, and one machine's three factors are spelled out, because "72%" tells the
supervisor that something is wrong and the three bars say which kind of person to call.

## What OEE comparisons cannot survive

OEE is standard in its formula and not in its inputs. One plant counts a mould change as planned and
another as a loss; one uses the speed in the machine's manual and another the best speed it has ever
reached. **Each choice moves the number by points, and none is wrong**, so an OEE comparison between
two plants is a comparison of two sets of choices unless both are written down and the same. The
"world class" OEE of around 85% that circulates in manufacturing is a rule of thumb rather than a
measurement, and Serra Azul's 72% says more set against IM-07's own last month than against it.
