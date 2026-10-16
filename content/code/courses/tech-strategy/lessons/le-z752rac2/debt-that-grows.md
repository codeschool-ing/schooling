---
title: The debt that grows
version: 1
---

The payback sheet treats interest as a constant: 31 hours this sprint, 31 the next, 31 a year from
now. **Some debts charge more every sprint**, because new code keeps being built on top of them, and
for those the sheet's payback is the optimistic case rather than the expected one.

## Why interest rises

The seat-hold locking is the example. Every feature that touches a seat hold — a new kind of ticket,
a change to the checkout flow, a screen for the Box Office app — is written around the row locks. Each
one becomes something else to rehearse and review, and something else to keep working on the day the
locks are finally removed. The workarounds are paid for in interest, and each one adds to the
interest after it.

When Davi measured the seat-hold debt again a few sprints later, the interest had grown by about 2
hours a sprint. Starting from 31, that is 33 the sprint after, 35 the one after that, and 57 by sprint
14 — nearly double where it began.

## Leave it, or pay it

Leaving the debt costs its interest every sprint, and the running total climbs. Paying it costs the
320 hours of the principal, once. **The sprint in which the running total of interest passes 320 is
the sprint in which leaving the debt has cost more than paying it would have.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"A line chart of hours paid against sprints 0 to 14. A flat amber line at 320 hours is the cost of paying the debt once. A dashed line, interest flat at 31 hours a sprint, crosses it after sprint 11. A solid line, interest rising by 2 hours a sprint, crosses it after sprint 9 at 351 hours and reaches 616 hours by sprint 14.\"><path d=\"M76 300.0 L680 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"304.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M76 260.0 L80 260.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100</text><path d=\"M76 220.0 L80 220.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"224.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M76 180.0 L80 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"184.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">300</text><path d=\"M76 140.0 L80 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"144.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M76 100.0 L80 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"104.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">500</text><path d=\"M76 60.0 L80 60.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"64.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><text x=\"80.0\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"122.9\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"165.7\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"208.6\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"251.4\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"294.3\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"337.1\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><text x=\"380.0\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><text x=\"422.9\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"465.7\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"508.6\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"551.4\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><text x=\"594.3\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"637.1\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">13</text><text x=\"680.0\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">14</text><text x=\"380.0\" y=\"344\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">sprints from today</text><text x=\"50\" y=\"24\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">hours paid so far</text><path d=\"M80.0 172.0 L680.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><polyline points=\"80.0,300.0 122.9,287.6 165.7,275.2 208.6,262.8 251.4,250.4 294.3,238.0 337.1,225.6 380.0,213.2 422.9,200.8 465.7,188.4 508.6,176.0 551.4,163.6 594.3,151.2 637.1,138.8 680.0,126.4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></polyline><polyline points=\"80.0,300.0 122.9,287.6 165.7,274.4 208.6,260.4 251.4,245.6 294.3,230.0 337.1,213.6 380.0,196.4 422.9,178.4 465.7,159.6 508.6,140.0 551.4,119.6 594.3,98.4 637.1,76.4 680.0,53.6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></polyline><circle cx=\"465.7\" cy=\"159.6\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"551.4\" cy=\"163.6\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"455.7\" y=\"147.6\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">after sprint 9: 351 h</text><text x=\"561.4\" y=\"193.6\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">after sprint 11: 341 h</text><rect x=\"90\" y=\"44\" width=\"300\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><path d=\"M100 58 L132 58\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"140\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">leave it, interest rising 2 h a sprint</text><path d=\"M100 80 L132 80\" stroke=\"var(--paper-dim)\" stroke-width=\"2.5\" stroke-dasharray=\"6 4\"></path><text x=\"140\" y=\"84\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">leave it, interest flat at 31 h</text><path d=\"M100 102 L132 102\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><text x=\"140\" y=\"106\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pay it once: 320 h</text></svg>", "caption": "The seat-hold debt, left or paid. Where a line of interest crosses the 320 hours of the fix, leaving the debt has cost more than paying it would have — two sprints sooner when the interest rises."}
```

With the interest flat, the running total is 310 hours after sprint 10 and 341 after sprint 11, so it
crosses the principal after sprint 11. With the interest rising by 2 hours a sprint, it is 304 after
sprint 8 and 351 after sprint 9: it crosses **after sprint 9**, two sprints — a month — sooner.

The gap keeps widening after that. By sprint 14 the flat interest would have added up to 434 hours
(31 × 14), and the rising one to 616. The difference is 182 hours, R$ 27,300 at R$ 150, spent on
nothing but waiting.

## Build it in your sheet

Add another sheet and give it three columns. Row 2 holds the first sprint; from row 3 on, each row
adds 2 hours to the interest above it and adds the new interest to the running total:

| | A | B | C |
|---|---|---|---|
| 1 | Sprint | Interest (h) | Paid so far (h) |
| 2 | 1 | 31 | `=B2` |
| 3 | 2 | `=B2+2` | `=C2+B3` |

Fill A down to 14 and copy B3 and C3 down to row 15. Column C should read 31, 64, 99 and so on, and
row 10 — sprint 9 — is the first to pass 320, at 351. Change the 2 in B3 to 0 and copy it down again,
and the first value over 320 moves to row 12, sprint 11. That one cell is the whole difference
between the two lines in the figure.

## What a growing debt changes

**A growing debt can be fought by stopping the growth as well as by paying the principal.** The
interest rises because code keeps being built on the debt, so anything that slows the building slows
the rise. Coreto's strategy in lesson 1 does both. The Reservations team reviews every change to the
seat-hold code, which cuts the number of new workarounds, and the team's first two quarters go on
the hold path, starting with removing the locks, which pays the principal. The review rule would be worth having even if the
removal slipped.

The principal tends to grow as well. Each workaround is one more thing the fix has to handle, so the
320 hours of today become more if the work waits. The sheet keeps the principal fixed for simplicity,
which makes waiting look cheaper than it is.

Measure more than once. A single measurement of interest cannot show a trend; measuring the same debt
a quarter later tells you which debts are growing, and those move up the list whatever their payback
says today.

Compare the reporting replica. Nobody builds anything new on it, so its interest stays at 4 hours a
sprint, and its payback of 50 sprints means the same next year as it does now. **A flat debt can wait
on its payback; a growing one gets more expensive to leave every sprint**, and that difference belongs
in the register next to the two numbers.
