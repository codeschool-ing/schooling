---
title: The supply chain behind the shelf
version: 1
---

The empty hook in the garden aisle was not the buyer's fault, and it was not the warehouse's. It
started three weeks earlier, at a supplier. **A shelf is the last link of a chain**, and the
indicators that matter for a retailer's suppliers are the ones that predict an empty shelf before it
happens: how long a supplier takes, whether it sends everything ordered, and whether it sends it on
the day it promised.

## Three indicators, one supplier

The hose reel comes from one supplier, and Varanda places a purchase order with it every week or
two. Lívia pulled the eight orders from August to October 2025 out of the ERP, the system where
Varanda's purchases, stock and sales are recorded: the units ordered, the units received, and the
days late against the date the supplier promised. A 0 means on time or early.

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Order | Ordered | Received | Days late |
| 2 | PO 1 | 120 | 120 | 0 |
| 3 | PO 2 | 120 | 114 | 0 |
| 4 | PO 3 | 150 | 150 | 2 |
| 5 | PO 4 | 150 | 150 | 0 |
| 6 | PO 5 | 120 | 120 | 9 |
| 7 | PO 6 | 120 | 108 | 0 |
| 8 | PO 7 | 150 | 150 | 0 |
| 9 | PO 8 | 150 | 150 | 4 |

The supplier's own report to Varanda quotes its **fill rate**: units received over units ordered.
In row 10, the totals of B and C, and then the rate:

```localised
=SUM(B2:B9)      1080
=SUM(C2:C9)      1062
=ROUND(C10/B10*100,1)      98.3
```

98.3% looks like a reliable supplier. Now ask about each order instead of each unit. In E1 type
`In full`, in F1 `On time` and in G1 `OTIF`; in row 2, and copied down:

```localised
=IF(C2>=B2,1,0)      1
=IF(D2<=0,1,0)      1
=E2*F2      1
```

**On-time-in-full**, or OTIF, counts an order as good only when it arrived complete and on time;
multiplying the two flags gives 1 only when both are 1. Sum the three columns in row 10 and divide
each by the eight orders:

```localised
=ROUND(E10/8*100,1)      75
=ROUND(F10/8*100,1)      62.5
=ROUND(G10/8*100,1)      37.5
```

**Fill rate 98.3%, OTIF 37.5%**, for the same eight orders. Both are correct. The first counts units,
so six missing reels out of 120 barely move it, and it does not look at dates at all. The second
counts orders, and five of the eight failed one test or the other. **A supplier chooses to report
the first, and a retailer has to measure the second.**

## From a late order to an empty shelf

PO 5 arrived nine days late. It was the order meant to arrive before the garden season peaked, and
the stock page in this lesson shows what happened in between: the reel was on the shelf 18 days of
the 28, and the estimate of the sales lost in the other ten was 47 reels, R$ 13,583.

That link is the useful finding. **The supplier's average delay was under two days**, which nobody
would chase. What emptied the shelf was the one order that came nine days late. Lesson 9 built a
reorder point from daily demand and the supplier's lead time. A lead time that is usually met and
sometimes nine days late needs more safety stock than its average suggests, and the reorder rule
only knows that if somebody measures the spread as well as the mean.

## What is odd about this data

Supply-chain data comes from two records that were not made for each other. The purchase order is
typed when the buyer orders, with the date the supplier promised. The goods receipt is typed when
the warehouse checks the delivery in. **The receipt's date is the day somebody typed it, which is not
always the day the truck arrived**: a delivery that reaches the Contagem warehouse late on a Friday
may be checked in on Monday and count as three days late. Before Varanda scores a supplier on OTIF,
it has to decide whether "on time" means at the warehouse door or in the system, and whether it
means the date promised or the date Varanda asked for. Two retailers can score the same supplier
differently on the same deliveries, and each is right by its own written rule.

Caio Barreto, the operations director, took the OTIF figure to the supplier's quarterly meeting.
The fill rate was the supplier's slide; the OTIF was Varanda's, with PO 5 and the ten empty days
beside it.
