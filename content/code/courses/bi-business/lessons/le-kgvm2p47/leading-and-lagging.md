---
title: Leading and lagging, and the tree that joins them
version: 1
---

Monthly sales are the number everybody at Varanda watches, and they have one flaw as a guide: by
the time February's total is known, February is over. **A lagging indicator tells you whether you
arrived. A leading indicator moves earlier and tells you in time to steer.** Sales, profit and
staff turnover for the year are lagging. Visits to the site this week, the share of them that buy,
and the number of job offers turned down are leading.

The common mistake is to treat "leading" as a compliment, as though the earlier number were the
better one. It is better only if it really drives the result, and that has to be shown rather than
assumed. A leading indicator with no proven link to the result is an early number about nothing.

## A KPI tree

The way to show the link is to write the result as the arithmetic of its parts. For the online
shop, that arithmetic is exact:

**online sales = visits × conversion × average ticket**

Conversion is the share of visits that end in an order, and the average ticket is the value of an
order. Multiply the first two and you get the number of orders; multiply by the ticket and you get
sales. Varanda's online shop in 2025, in a new sheet from A1:

| | A | B |
|---|---|---|
| 1 | | Now |
| 2 | Visits | 3568000 |
| 3 | Conversion % | 1.25 |
| 4 | Average ticket | 350 |

In A5 type `Sales` and in A6 `Orders`, then:

```localised
B5   =B2*B3/100*B4      15610000
B6   =B2*B3/100         44600
```

**R$ 15.61 million**, the online figure from lesson 1, rebuilt from three numbers that each move
every day. That is what makes the tree useful: the result at the top is known once a month, and the
branches are known by Monday.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A KPI tree. At the top, online sales, a lagging result. Below it, multiplied together, visits, conversion and average ticket. Below each, what drives it: campaigns, search and email for visits; price, stock on the shelf, site speed and the delivery promise for conversion; the mix of products and items per order for the ticket. Each branch names an owner.\" data-fig=\"l10-tree\"><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">online sales</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 15.61 million in 2025</text><text x=\"475.0\" y=\"44.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lagging</text><rect x=\"20.0\" y=\"150.0\" width=\"200.0\" height=\"78.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">visits</text><text x=\"120.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3,568,000</text><text x=\"120.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">owner: Renata</text><path d=\"M120.0 150.0 L120.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"260.0\" y=\"150.0\" width=\"200.0\" height=\"78.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">conversion</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1.25% of visits buy</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">owners: Renata and Caio</text><path d=\"M360.0 150.0 L360.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"500.0\" y=\"150.0\" width=\"200.0\" height=\"78.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"174.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">average ticket</text><text x=\"600.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 350 per order</text><text x=\"600.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">owner: Renata</text><path d=\"M600.0 150.0 L600.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M120.0 116.0 L600.0 116.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M360.0 116.0 L360.0 84.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"240.0\" y=\"138.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">×</text><text x=\"480.0\" y=\"138.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">×</text><text x=\"700.0\" y=\"138.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leading</text><path d=\"M120.0 230.0 L120.0 262.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"20.0\" y=\"264.0\" width=\"200.0\" height=\"112.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">paid campaigns</text><text x=\"36.0\" y=\"312.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">search</text><text x=\"36.0\" y=\"334.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">email</text><path d=\"M360.0 230.0 L360.0 262.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"260.0\" y=\"264.0\" width=\"200.0\" height=\"112.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"276.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">price</text><text x=\"276.0\" y=\"312.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">stock on the shelf</text><text x=\"276.0\" y=\"334.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">site speed</text><text x=\"276.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">delivery promise</text><path d=\"M600.0 230.0 L600.0 262.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"500.0\" y=\"264.0\" width=\"200.0\" height=\"112.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"516.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">product mix</text><text x=\"516.0\" y=\"312.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">items per order</text></svg>", "caption": "Online sales as a tree. The result at the top arrives once a month; the three branches move daily, and the drivers under them are what somebody can actually change. Conversion has two owners because the delivery promise and the stock belong to operations."}
```

The bottom row of the figure is where work happens. Nobody can "increase conversion" directly; they
can cut the price of a product, keep it in stock, make the page load faster, or promise a shorter
delivery. **A tree ends where somebody can act**, and that is also where its owners are. Conversion
has two, because the stock on the shelf and the delivery promise belong to Caio, not to Renata. A
tree drawn this way settles in advance the argument about whose fault a bad month was.

## Why a branch on its own misleads

Renata's agency proposes a heavier year of paid campaigns for 2026, which it expects to raise visits by
a quarter. Suppose it does, and the new visitors are less ready to buy than the old ones, so that conversion falls to
1%. In C1 type `Campaign`, `1` in C3 and `350` in C4, and let C2 raise the visits by a quarter:

```localised
C2   =B2*1.25           4460000
C5   =C2*C3/100*C4      15610000
C6   =C2*C3/100         44600
```

**Visits up 25%, sales unchanged to the last real.** The campaign's own report, which counts visits,
will call it a success, and the tree says it bought nothing. The opposite case shows the other side
of the multiplication. Hold visits and ticket where they were and raise conversion from 1.25% to
1.375%, a tenth more, and sales rise by a tenth too:

```localised
=B2*1.375/100*B4                         17171000
=ROUND((B2*1.375/100*B4/B5-1)*100,1)     10
```

The parts of a product move the result in proportion, so **a branch is only good news if the
others held still**, and the tree is how you see whether they did.

## What a tree is not

A tree like this one is an identity: it is true by arithmetic, whatever happens. Many trees people
draw are not. "Staff training hours drive customer satisfaction, which drives sales" is a
hypothesis written in the shape of a tree, and the arrows in it have to be checked against data
before anybody manages by them. Lesson 7 showed how two numbers can move together for a third
reason; `statistics` lesson 18 gives that its proper treatment. Draw the exact parts with confidence
and the guessed ones with a dotted line.
