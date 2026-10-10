---
title: Operations: stock, the warehouse and deliveries
version: 1
---

Operations is everything that happens to the goods between the supplier and the customer: buying
them, holding them, moving them to a store or a front door. At Varanda that is Caio Barreto's area,
with the warehouse in Contagem at its centre. **Its numbers are about two things that pull against
each other: having the right goods where customers want them, and not tying up money in goods nobody
is buying.** Most operational decisions are a choice of where to sit between the two.

## Stock: how much, and how fast it moves

Stock is money in the shape of sofas. Varanda held, on average across the twelve month-ends of 2025,
R$ 9.48 million of stock at cost. On its own that number says nothing; set against the cost of what
was sold in the year, R$ 55.37 million from the finance section, it says how fast the goods move.
Type the two into a sheet, cost of goods sold in B2 and average stock in B3:

```localised
=ROUND(B2/B3,1)          5.8
=ROUND(B3/B2*365,1)      62.5
```

**Stock turned 5.8 times in the year, which is the same fact as 62.5 days of stock**: on average an
item sat for about two months between arriving and being sold. The two are the same number upside
down, and companies use one or the other by habit. Both are averages over very different goods. A
pack of seeds may sell in a week while a dining table waits half a year, which is why operations
looks at days of stock by category, never only for the whole company.

What a day of stock costs is a sum worth having in your head:

```localised
=ROUND(B2/365,1)      151.7
```

**One more day of stock ties up about R$ 152,000** at cost — money that is not in the bank, paying
for warehouse space, and at risk of going out of fashion.

## Deliveries: on time, and how long

Furniture leaves the warehouse on Varanda's own trucks. In 2025 they made 14,600 deliveries, and 949
arrived after the promised date, the same records Caio misremembered in lesson 2:

```localised
=ROUND((14600-949)/14600*100,1)      93.5
```

**93.5% on time.** Next to it operations watches the **lead time**, the days between the order and
the delivery, because a delivery can be on time against a promise of three weeks and still lose the
customer to a competitor who promises three days. What "on time" means — the promised day, or within
a window, counting or not the deliveries the customer rescheduled — is a definition, and lesson 10
shows two reasonable versions giving two different rates.

## The trade-off

The tension in the opening paragraph has a name: **service level against stock cost.** Hold more
stock and fewer customers find an empty shelf, but more money sits in the warehouse. Hold less and
the money is freed, but some customers leave without buying, and nothing in the sales data records
the sale that did not happen. Faster deliveries need more trucks or more stock closer to the
customer; both cost money.

There is no right answer in general, only a right answer for a product and a season. **What an
analyst brings is the numbers on both sides of the scale**, so that Caio's decision about Christmas
stock is a choice between two known costs instead of between a worry about empty shelves and a worry
about the bank balance. Lesson 9 computes one of those decisions, a reorder point, with numbers.
