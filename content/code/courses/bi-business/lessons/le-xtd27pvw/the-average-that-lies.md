---
title: The average that describes nobody
version: 1
---

On Monday 16 March 2026 Renata's weekly report showed the average ticket of the online shop's new
garden-furniture pages at **R$ 2,607**, against R$ 350 for the whole online shop in 2025. The pages
had gone live the week before, and the first reading in the meeting was that they had worked
spectacularly. Nobody had made an arithmetic mistake. **The number was correct, and it described
none of the week's customers.**

This lesson is about numbers like that one: computed correctly from correct data, and still
pointing a meeting at the wrong conclusion. Lesson 1 called it "not the truth by default"; here are
the five shapes it takes most often, starting with the average.

## Twelve orders

The pages took twelve orders in their first week, in reais. Type them into a new sheet from A1:

| | A | B |
|---|---|---|
| 1 | Order | Value |
| 2 | 1 | 189 |
| 3 | 2 | 245 |
| 4 | 3 | 312 |
| 5 | 4 | 278 |
| 6 | 5 | 420 |
| 7 | 6 | 156 |
| 8 | 7 | 365 |
| 9 | 8 | 298 |
| 10 | 9 | 540 |
| 11 | 10 | 233 |
| 12 | 11 | 18400 |
| 13 | 12 | 9850 |

Orders 11 and 12 came from an architect's office furnishing a hotel in Belo Horizonte: sixty garden
chairs in one, the loungers for the pool in the other. Now the average, which is what "average
ticket" means on Renata's report, and the median:

```localised
=ROUND(AVERAGE(B2:B13),0)      2607
=MEDIAN(B2:B13)                305
```

The **mean** adds the values and divides by how many there are: R$ 31,286 over twelve orders. The
**median** sorts them and takes the middle; with twelve, it is halfway between the sixth and the
seventh. **Two orders out of twelve carry 90.3% of the money**, so they drag the mean to a value
where no order sits, while the median stays among the customers:

```localised
=ROUND((B12+B13)/SUM(B2:B13)*100,1)      90.3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Twelve orders as dots on one line from 0 to 20,000 reais. Ten sit crowded together at the far left, all below 600 reais. Two sit far to the right, at 9,850 and 18,400. The median, 305 reais, is marked inside the crowd; the mean, 2,607 reais, is marked in the empty space between the crowd and the two large orders, where no order is.\" data-fig=\"l12-orders\"><path d=\"M40.0 96.0 L680.0 96.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M40.0 96.0 L40.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"40.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M200.0 96.0 L200.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"200.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5,000</text><path d=\"M360.0 96.0 L360.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"360.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">10,000</text><path d=\"M520.0 96.0 L520.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"520.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">15,000</text><path d=\"M680.0 96.0 L680.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"680.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">20,000</text><text x=\"680.0\" y=\"138.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reais per order</text><path d=\"M42.0 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M43.8 79.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M46.0 72.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M44.9 65.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M49.4 58.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M41.0 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M47.7 79.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M45.5 72.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M53.3 65.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M43.5 58.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M624.8 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M351.2 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M123.4 30.0 L123.4 96.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"131.4\" y=\"34.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">mean R$ 2,607</text><text x=\"131.4\" y=\"50.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no order is near it</text><path d=\"M49.8 152.0 L49.8 126.0\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"45.8\" y=\"172.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">median R$ 305</text><text x=\"45.8\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">half the orders below, half above</text><text x=\"492.0\" y=\"74.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the hotel's two orders</text></svg>", "caption": "The week's twelve orders. Ten of them, every ordinary customer, fit in the first sliver of the axis. The mean sits where nobody bought anything."}
```

## Neither number is wrong

The tempting conclusion is "the median is right and the mean lies". It is not that simple. **The
mean answers a question about money: total revenue divided by orders.** If Otávio wants to know how
much a thousand more orders like this week's would bring in, the mean is the number to use, and the
median would underestimate it badly. **The median answers a question about people: what a typical
customer spends.** If Renata wants to know whether the new pages changed how ordinary customers buy,
the median is the one to look at, and it says R$ 305: below the shop's usual ticket, not seven
times above it.

The failure is not in either formula. It is in a report that writes "average ticket" and lets the
reader assume it describes a typical customer. Three habits prevent it:

- **Put the median beside the mean** wherever a few large values are possible. When the two are far
  apart, that distance is the finding.
- **Look at the largest values before reporting the average.** Two rows out of twelve were obvious
  the moment anybody sorted the column.
- **Report a different kind of customer separately.** The hotel was a business buying for a project,
  not a household. Take orders 11 and 12 out and the household orders look like this:

```localised
=ROUND(AVERAGE(B2:B11),0)      304
```

R$ 304 for the households, and the business orders reported on their own line. That is two numbers
where the report had one, and both are true.

Why some kinds of data pull the mean away from the middle, and how to describe the spread around
it, belongs to `statistics` lessons 3, 4 and 9. What this course asks is narrower and comes first:
before an average reaches a meeting, somebody looks at the rows behind it.
