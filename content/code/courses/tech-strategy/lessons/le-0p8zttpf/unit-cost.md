---
title: Unit cost: the number that can go down while the bill goes up
version: 1
---

Coreto's plan for next year has the cloud bill rising from R$ 212,000 a month to R$ 236,000. Shown
to Otávio on its own, that is **an increase of 11.3%**, and the natural reaction is to ask
engineering why it is spending more. The question assumes the bill should stay flat. It should not,
because next year Coreto expects to sell 520,000 tickets a month instead of 410,000, and serving
more tickets costs more.

The bill alone cannot say whether engineering is getting better or worse at its job. A bill divided
by what the business sells can.

## Cost per ticket

Coreto earns a fee on every ticket, so the ticket is the natural unit: **cloud cost per ticket
sold**. In your spreadsheet, as set up in lesson 1, this year's:

```localised
=ROUND(212000/410000,3)      0.517
```

And next year's plan:

```localised
=ROUND(236000/520000,3)      0.454
```

**The bill rises 11.3% and the cost of serving one ticket falls 12.2%**, from R$ 0.517 to R$ 0.454.
Presented that way, the plan says the opposite of what the bill alone said: the platform is
expected to get cheaper per unit of business while the business grows. That is the sentence
Otávio needs, and it is a different conversation from "why is engineering spending more".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-unit\" aria-label=\"Two panels, each with two bars: this year and next year's plan. Left, the monthly cloud bill rises from R$ 212,000 to R$ 236,000, up 11.3%. Right, the cloud cost per ticket sold falls from R$ 0.517 to R$ 0.454, down 12.2%.\"><rect x=\"20.0\" y=\"14.0\" width=\"330.0\" height=\"222.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"38.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Monthly cloud bill</text><text x=\"185.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">+11.3%</text><rect x=\"90.0\" y=\"105.4\" width=\"60.0\" height=\"100.6\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"120.0\" y=\"98.4\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 212,000</text><text x=\"120.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">this year</text><rect x=\"220.0\" y=\"94.0\" width=\"60.0\" height=\"112.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"250.0\" y=\"87.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 236,000</text><text x=\"250.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">next year's plan</text><rect x=\"370.0\" y=\"14.0\" width=\"330.0\" height=\"222.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"38.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Cloud cost per ticket sold</text><text x=\"535.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">−12.2%</text><rect x=\"440.0\" y=\"94.0\" width=\"60.0\" height=\"112.0\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"470.0\" y=\"87.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 0.517</text><text x=\"470.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">this year</text><rect x=\"570.0\" y=\"107.6\" width=\"60.0\" height=\"98.4\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"600.0\" y=\"100.6\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 0.454</text><text x=\"600.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">next year's plan</text></svg>", "caption": "The same plan read two ways. The bill rises because Coreto sells more tickets; each ticket costs less to serve. Only the right-hand panel says whether the platform is getting more or less efficient."}
```

## Choosing the unit

A unit cost is only as useful as its unit, and three tests pick a good one.

**It is something the business earns from.** Tickets work at Coreto because the fee is per ticket,
so cost per ticket can be set beside revenue per ticket and read as a margin. A unit the business
does not sell, such as cost per server or cost per engineer, measures an input and says nothing
about whether the spending was worth it.

**Its definition stays still.** If "a ticket" means tickets sold this quarter and tickets issued
including free ones next quarter, the trend measures the change of definition. Write the definition
down beside the number.

**The teams can move it.** A unit nobody's decisions affect is a statistic rather than a target.
Cost per ticket moves when Checkout makes a page cheaper to serve, when Data keeps fewer copies of
the event history, when Platform turns off idle machines. Each team can also have a unit of its own
— Catalogue's cost per search, for instance — as long as it rolls up to the company's.

## What it hides

Unit cost is the best single number for a cloud bill, and it still hides two things a lead should
know about.

**Part of the fall is scale, not skill.** Some of the bill does not grow with tickets at all: the
monitoring, the build machines, the environments that exist whether one ticket is sold or a million.
Spread over more tickets, that fixed part makes every ticket look cheaper without anybody changing
anything. Coreto's plan has tickets growing 26.8% (520,000 against 410,000) and the bill growing
11.3%, and some of the gap would appear even if no team did any work on cost. Before crediting a
falling unit cost to an improvement, ask which part of the bill moved.

**It can fall while waste grows.** A staging environment left running all weekend costs the same
whether 410,000 tickets are sold or 520,000. As sales grow, its share of the cost per ticket shrinks
and it becomes harder to see in the unit cost, while it is still there on the bill. The
last section of this lesson finds exactly that at Coreto.

## Why it lasts

Providers will keep changing how they charge. Unit cost survives every change, because it asks a
question about the business rather than about the provider's price list. **A number that compares
next year with this year, whatever the provider has renamed in between, is the one to report every
month**, and it is the first line of the monthly review in the operate phase. The next section adds
the second line: whose decisions the bill is made of.
