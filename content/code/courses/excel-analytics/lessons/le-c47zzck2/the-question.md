---
title: Who reads it, and what they decide
version: 1
---

**A dashboard is designed backwards, from the decision it serves to the cells that serve it.** The
usual way is the other direction: open the data, make every chart it allows, and arrange them on a
sheet. The result shows everything and answers nothing, because nobody said what it was for.

Café Serra's dashboard has one reader and one decision. The owner opens it at the start of each
month and decides where the next quarter's effort goes: more visits to wholesale customers, a
promotion on the web shop, more stock of one product and less of another. Everything on the sheet
has to help with that decision, and anything that does not help comes off.

## From the decision to four KPIs

The course `bi-business`, at position 2 of the track, gives the vocabulary. A **metric** is any
number you can compute from the data. A **KPI** is one of the few metrics somebody has chosen to
steer by, and it comes with a definition, a comparison, an owner and a frequency. Café Serra has
hundreds of possible metrics and needs four KPIs:

| KPI | definition | measure | Jan–Jun 2026 | Jan–Jun 2025 |
|---|---|---|---|---|
| **Revenue** | the sum of `Bags` × `Price` over the period | `Total Revenue` | R$ 15,943 | R$ 17,789 |
| **Bags** | bags sold in the period | `Bags Sold` | 168 | 218 |
| **Sales** | sales recorded in the period | `Sales Count` | 36 | 36 |
| **Average sale** | revenue divided by sales | `Average Sale` | R$ 443 | R$ 494 |

The first three measures are lesson 16's. The fourth is one more line in the same place, built from
two that already exist. Lesson 16's `Average Price` divides revenue by bags; this one divides it by
sales, because the owner's question is about orders as much as about coffee:

```dax
Average Sale := DIVIDE ( [Total Revenue], [Sales Count] )
```

The owner is the person who opens the dashboard, and the frequency is monthly. The comparison is
the column on the right, and it is the part people leave out.

## A number with nothing beside it is not a KPI

R$ 15,943 on its own tells the owner nothing. Is that good? Beside R$ 17,789 for the same six
months of 2025 it says revenue is **10.4% lower** than a year ago, and that is something to act on.
The `Revenue YoY %` measure of lesson 16 is exactly that comparison, and it goes on the screen next to every
number it applies to.

The comparison has to be **like with like**, the trap lesson 16 met. January to June 2026 against
the whole of 2025 puts six months against twelve and shows a fall of 55.2%, which is false and
alarming. The same months a
year earlier is the fair comparison when nothing else is available, and it is what lesson 16's
`Revenue LY` computes.

A KPI in the full sense also has a **target**, a number somebody committed to. Café Serra's data
has none, so last year stands in for one. A dashboard that has a target should show it, because
"10.4% below last year" and "2% above the plan" can both be true at once, and the plan is what the
owner agreed to.

## And one that stays off

Gross margin looks like an obvious fifth KPI, and lesson 16 already built `Gross Margin` and
`Margin %` from the `Unit cost` column of `Products`. But that column holds **one cost per product,
today's**. On a dashboard whose whole point is this year against last, the 2025 margin would be
computed with 2026 costs, and nothing on the screen would say so.

A dashboard is believed because it looks finished, so **a KPI the data cannot support honestly stays
off it** until the data can. Here that means a table of costs with the date each one took effect.
The owner is better served by four true numbers than by
five where one is quietly wrong.
