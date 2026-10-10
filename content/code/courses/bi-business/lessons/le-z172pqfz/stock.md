---
title: Stock, and the sale that left no record
version: 1
---

A retailer's money sits on its shelves before it reaches the till. Too little stock and customers
leave empty-handed; too much and the cash is tied up in clay pots for a year and a half. The
indicators for this decision answer two questions about each product: **how long will what we hold
last, and how much of what we had did we sell?**

The trap is in the data, and it is worth naming first. **A stock-out does not show up in sales data
as low sales. It does not show up at all.** The till records what was sold. A customer who came for
a hose reel, found the hook empty and left recorded nothing, and a report that adds up receipts
will show a quiet fortnight for hose reels and draw no attention to it.

## Days of cover and sell-through

Varanda's garden category, the four weeks to Sunday 26 October 2025, which is spring in Minas
Gerais and the busiest season for garden products. For each product: the units on hand that Sunday
night, the units sold in the 28 days, the days of the 28 on which there was stock to sell, and the
price in reais. Type it in a new sheet:

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Product | On hand | Sold | Days in stock | Price |
| 2 | Hose reel, 30 m | 0 | 84 | 18 | 289 |
| 3 | Garden hose, 15 m | 410 | 196 | 28 | 79 |
| 4 | Pruning shears | 95 | 133 | 28 | 64 |
| 5 | Clay pot, 30 cm | 1240 | 62 | 28 | 45 |
| 6 | Oscillating sprinkler | 36 | 150 | 28 | 119 |
| 7 | Potting soil, 20 kg | 300 | 360 | 25 | 39 |

**The daily rate is units sold divided by the days there was something to sell**, not by 28. A
product that sold 84 units in 18 days sells 4.67 a day, and dividing by 28 would hide the ten
empty days inside a lower average. In F2, and copied down:

```localised
=ROUND(C2/D2,2)      4.67
```

**Days of cover** is how long the stock on hand lasts at that rate. In G2:

```localised
=ROUND(B2/(C2/D2),1)      0
```

**Sell-through** is the share of the stock available in the period that sold. Definitions vary
between retailers; this one divides units sold by units sold plus units left. In H2:

```localised
=ROUND(C2/(C2+B2)*100,1)      100
```

Copied down, the columns say three different things. The clay pot has **560 days of cover** and a
sell-through of 4.8%: R$ 55,800 of pots at the shelf price, enough for eighteen months at this rate.
The sprinkler has 6.7 days left. And the hose reel has a sell-through of 100%, which looks like the
best result in the category and is the worst: **every reel Varanda had was sold, and then there
were none for ten days.**

## Pricing the empty shelf

The sale that left no record can still be estimated. If the reel sold 4.67 a day while it was on
the shelf, the ten empty days lost about 4.67 × 10 of them. In I2, copied down, and in J2 the same
in reais:

```localised
=ROUND(C2/D2*(28-D2),0)      47
=I2*E2      13583
```

Potting soil was out for three days and lost 43 bags, R$ 1,677. Sum the two columns:

```localised
=SUM(I2:I7)      90
=SUM(J2:J7)      15260
```

**R$ 15,260 of sales the receipts will never show**, from two products in one category in four
weeks. It is an estimate, and it leans high: it assumes every customer who found the hook empty
would have bought one, and some bought a cheaper hose instead or came back the next week. It also
leans low, because a customer who leaves without the reel may leave without the rest of the
basket. Write the assumption beside the number, and the number is still far better than the zero
that the receipts imply.

There is a second cost, and it arrives months later. A forecast built from sales history, like the
ones in lesson 8, learns from those ten days that hose reels do not sell in October. Next spring it
orders fewer, and the shelf empties sooner.

## The page the buyer opens

The person who decides what to reorder is the category's buyer, and the question they bring on
Monday morning is the operational one from lesson 14: **what needs my attention now?** The page is
built for that question.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"A mock of a stock page for the garden category, four weeks to Sunday 26 October 2025, updated Monday at 06:10. Four tiles across the top: 1 product out of stock; 1 with under 14 days of cover; 1 with over 180 days of cover; estimated lost sales R$ 15.3 thousand. Below, a table of six products ordered by urgency: the hose reel is out of stock, with 10 days out and 47 units lost; the sprinkler has 6.7 days of cover; the clay pot has 560 days of cover; potting soil, pruning shears and the garden hose are fine.\" data-fig=\"l18-stock-page\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"400.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Garden · stock</text><text x=\"692.0\" y=\"34.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">four weeks to Sun 26 Oct 2025</text><text x=\"692.0\" y=\"50.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">updated Mon 27 Oct, 06:10</text><rect x=\"28.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"40.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">out of stock</text><rect x=\"196.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"208.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"208.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cover under 14 days</text><rect x=\"364.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"376.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"376.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cover over 180 days</text><rect x=\"532.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"544.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">R$ 15.3k</text><text x=\"544.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lost sales, estimated</text><text x=\"28.0\" y=\"176.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">product</text><text x=\"330.0\" y=\"176.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">on hand</text><text x=\"440.0\" y=\"176.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">days of cover</text><text x=\"548.0\" y=\"176.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">days out</text><text x=\"566.0\" y=\"176.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">status</text><path d=\"M28.0 184.0 L692.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"28.0\" y=\"208.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Hose reel, 30 m</text><text x=\"330.0\" y=\"208.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"440.0\" y=\"208.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0.0</text><text x=\"548.0\" y=\"208.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">10</text><path d=\"M566.0 198.0 H576.0 V208.0 H566.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"584.0\" y=\"208.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">out of stock</text><text x=\"28.0\" y=\"238.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Oscillating sprinkler</text><text x=\"330.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">36</text><text x=\"440.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">6.7</text><text x=\"548.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M566.0 228.0 H576.0 V238.0 H566.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"584.0\" y=\"238.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reorder now</text><text x=\"28.0\" y=\"268.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Clay pot, 30 cm</text><text x=\"330.0\" y=\"268.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1,240</text><text x=\"440.0\" y=\"268.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">560.0</text><text x=\"548.0\" y=\"268.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M566.0 258.0 H576.0 V268.0 H566.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"584.0\" y=\"268.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">overstock</text><text x=\"28.0\" y=\"298.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Potting soil, 20 kg</text><text x=\"330.0\" y=\"298.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">300</text><text x=\"440.0\" y=\"298.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20.8</text><text x=\"548.0\" y=\"298.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text><text x=\"584.0\" y=\"298.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ok</text><text x=\"28.0\" y=\"328.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pruning shears</text><text x=\"330.0\" y=\"328.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">95</text><text x=\"440.0\" y=\"328.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20.0</text><text x=\"548.0\" y=\"328.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"584.0\" y=\"328.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ok</text><text x=\"28.0\" y=\"358.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Garden hose, 15 m</text><text x=\"330.0\" y=\"358.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">410</text><text x=\"440.0\" y=\"358.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">58.6</text><text x=\"548.0\" y=\"358.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"584.0\" y=\"358.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ok</text><text x=\"28.0\" y=\"396.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">days of cover = units on hand ÷ units sold per day in stock</text></svg>", "caption": "A stock page built for the person who buys the category. It opens on the exceptions, puts a money figure on the shelf that was empty, and leaves the products that are fine at the bottom."}
```

Three choices in the mock are worth copying. The products are ordered by urgency, so the empty
shelf is the first row and the four products that are fine sit at the bottom, where nobody needs to
read them. The lost-sales tile puts a figure in reais on the empty shelf, because "47 units" is a
stock problem and "R$ 15.3 thousand" is a conversation with the operations director. And the page
says when it was updated, because a stock position from Friday is a different page from one taken
this morning.

What the page does not show is a chart of the category's sales by month. That belongs in the
monthly review of lesson 15, and here it would push the empty hook below the fold.
