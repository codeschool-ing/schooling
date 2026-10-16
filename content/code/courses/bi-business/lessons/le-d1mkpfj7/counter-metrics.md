---
title: The guard beside every KPI
version: 1
---

Lesson 10 ended with a target met without delivering faster. That is not a story about dishonest
people. **Any number that people are rewarded for will be moved by the cheapest route available**,
and the cheapest route is often not the one the number was chosen to measure. The economist Charles
Goodhart made the point about monetary targets in the 1970s, and its common wording is the
anthropologist Marilyn Strathern's: *when a measure becomes a target, it ceases to be a good
measure*.

The wrong conclusion is that targets are a bad idea. A KPI nobody is held to is a number nobody acts
on, and lesson 10 spent a section building one that somebody is. The right conclusion is narrower:
**a KPI that matters needs a second number beside it, chosen to move when the first one is met the
wrong way.** This lesson calls it the guard; it also goes by counter-metric.

## What happened at Varanda

In March 2026 Caio's carriers were told that delivered on promise would decide part of their
contract. By May the KPI read 86.2%, up from February's 76.9%, which is above the 85% goal set for
December. Damaged deliveries were on the page too, because they came second in the scoring sheet of
the last section. In a new sheet:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Month | Delivered | Damaged | On promise % |
| 2 | Feb | 1840 | 22 | 76.9 |
| 3 | May | 1910 | 59 | 86.2 |

```localised
=ROUND(C2/B2*100,1)      1.2
=ROUND(C3/B3*100,1)      3.1
```

**The damage rate went from 1.2% to 3.1%** while deliveries barely grew. Vans were being loaded in a
hurry and driven to make the date, and sofas were arriving on time with a torn arm. On its own the
KPI said the contract clause worked; with its guard beside it, the page said that part of the gain
had been bought with customers' furniture. Caio did not drop the clause. He added a damage
condition to it.

## Choosing the guard

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 328\" role=\"img\" aria-label=\"Four pairs. On the left a KPI, on the right the guard that watches it, and between them the way the KPI is met without improving anything: delivered on promise and damaged deliveries; call handling time and repeat calls within seven days; online conversion and the returns rate; stock-outs and days of stock.\" data-fig=\"l11-pairs\"><text x=\"115.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">KPI</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the shortcut it invites</text><text x=\"605.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the guard</text><rect x=\"20.0\" y=\"44.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"75.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">delivered on promise</text><rect x=\"510.0\" y=\"44.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"75.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">damaged deliveries</text><path d=\"M212.0 70.0 L508.0 70.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"63.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">rush the van, drop the sofa</text><rect x=\"20.0\" y=\"116.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"147.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">call handling time</text><rect x=\"510.0\" y=\"116.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"147.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">repeat calls in 7 days</text><path d=\"M212.0 142.0 L508.0 142.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"135.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">end the call before it is solved</text><rect x=\"20.0\" y=\"188.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"219.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">online conversion</text><rect x=\"510.0\" y=\"188.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"219.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">returns rate</text><path d=\"M212.0 214.0 L508.0 214.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"207.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sell what does not fit the room</text><rect x=\"20.0\" y=\"260.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"291.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">stock-outs</text><rect x=\"510.0\" y=\"260.0\" width=\"190.0\" height=\"52.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"291.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">days of stock</text><path d=\"M212.0 286.0 L508.0 286.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"279.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fill the warehouse</text></svg>", "caption": "Each KPI with the guard read beside it. The middle column is why the guard exists: the cheapest way to move the number on the left shows up in the number on the right."}
```

The guard is found by asking one question of each KPI: **what is the cheapest way to move this
number without improving what it stands for?** Whatever that shortcut damages is what the guard
measures.

- Delivered on promise is met by rushing, so the guard is damaged deliveries. It is also met by
  lengthening the promise, which is why the promised days are written on the card, where a change
  has to be argued.
- A call centre's handling time is met by ending calls before the problem is solved, so the guard is
  the share of customers who call again within seven days.
- Online conversion is met by selling to people who will return the product, so the guard is the
  returns rate.
- Stock-outs are met by filling the warehouse, so the guard is days of stock, which costs Otávio
  money every day it grows.

The pairs work because the two numbers pull in opposite directions. Days of stock and stock-outs
cannot both be pushed down by the same lazy move, and a warehouse that improves both has really
improved. **A guard is read beside its KPI, every time, never on a different page**, because a
different page is one people do not open on a good week.

## The guard is not a sixth KPI

A guard does not need a target of its own, and it does not need an owner who is different from the
KPI's. It needs a line on the KPI's card saying which number keeps it honest, and a threshold at
which the two are discussed together. That keeps the page short: in the scoring sheet, damaged
deliveries and days of stock earned their places on their own, and they double as guards for two of
the others. **The best indicators on a short page often do both jobs.**
