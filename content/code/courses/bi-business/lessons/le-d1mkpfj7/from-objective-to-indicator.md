---
title: From objective to indicator
version: 1
---

The usual way an indicator page is built is to list what the systems can produce and pick the ones
that look important. That starts from the data, which lesson 1 named as one of the two ways the BI
cycle breaks, and it ends with a page of numbers that are easy to get. **The method that works runs
the other way: objective, then the questions the objective raises, then the indicator that answers
each question.** Software engineers know it as goal-question-metric, from a method for measuring
software projects; the name does not matter, the order does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A tree read from left to right. One objective, keep the date we give the customer, leads to three questions: are we late, and where; do we damage what we deliver; is the product there to send. Each question leads to the indicator that answers it: delivered on promise by route, damaged deliveries, and stock-outs among the top 200 products.\" data-fig=\"l11-gqm\"><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">objective</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">questions</text><text x=\"605.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">indicators</text><rect x=\"20.0\" y=\"125.0\" width=\"180.0\" height=\"80.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"158.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">keep the date we</text><text x=\"110.0\" y=\"178.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">give the customer</text><rect x=\"255.0\" y=\"50.0\" width=\"210.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"85.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">are we late, and where?</text><rect x=\"510.0\" y=\"50.0\" width=\"190.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"77.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">delivered on promise</text><text x=\"605.0\" y=\"96.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">by route, weekly</text><path d=\"M202.0 165.0 L253.0 80.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M253.0 80.0 L252.2 89.0 L245.5 84.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M467.0 80.0 L508.0 80.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 80.0 L499.9 83.9 L499.9 76.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"255.0\" y=\"145.0\" width=\"210.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">do we damage what we deliver?</text><rect x=\"510.0\" y=\"145.0\" width=\"190.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"172.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">damaged deliveries</text><text x=\"605.0\" y=\"191.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">percent, weekly</text><path d=\"M202.0 165.0 L253.0 175.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M253.0 175.0 L244.3 177.3 L245.8 169.6 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M467.0 175.0 L508.0 175.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 175.0 L499.9 178.9 L499.9 171.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"255.0\" y=\"240.0\" width=\"210.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"275.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">is the product there to send?</text><rect x=\"510.0\" y=\"240.0\" width=\"190.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"267.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">stock-outs, top 200</text><text x=\"605.0\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">days out, weekly</text><path d=\"M202.0 165.0 L253.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M253.0 270.0 L245.9 264.4 L253.0 261.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M467.0 270.0 L508.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 270.0 L499.9 273.9 L499.9 266.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"360.0\" y=\"322.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an indicator with no question above it has no reason to be on the page</text></svg>", "caption": "Objective, questions, indicators, for Caio's delivery objective. Read from the left it chooses the indicators; read from the right it is the written reason each one is there."}
```

Caio's objective from lesson 10 is to keep the date Varanda gives the customer. It raises three
questions he will ask every week: are we late, and where? Do we damage what we deliver? Is the
product in the warehouse to be sent at all? Each question picks its own indicator, and each
indicator has a sentence above it saying why it is there. **An indicator with no question above it
has no reason to be on the page**, however easy it is to compute.

## Scoring the candidates

In practice the list of candidates is longer than the questions, because each director arrives with
a few. Lívia collected ten for Caio's page, and scored each from 1 to 5 on four criteria:

- *relevant*: how directly it answers one of the objective's questions;
- *actionable*: whether Caio's team can change it within weeks;
- *data*: whether the records exist and can be trusted;
- *cheap*: how little work it takes to produce every week (5 is the cheapest).

Relevance and action matter more than convenience, so they weigh 3 and the other two weigh 2. Type
the table into a new sheet from A1; row 2 holds the weights:

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Indicator | Relevant | Actionable | Data | Cheap |
| 2 | Weight | 3 | 3 | 2 | 2 |
| 3 | Delivered on promise | 5 | 5 | 4 | 4 |
| 4 | Damaged deliveries | 4 | 5 | 4 | 4 |
| 5 | Stock-outs, top 200 | 5 | 4 | 3 | 3 |
| 6 | Days of stock | 4 | 3 | 5 | 5 |
| 7 | Picking errors | 4 | 5 | 3 | 3 |
| 8 | Delivery cost per order | 4 | 4 | 4 | 3 |
| 9 | Pallets received a day | 2 | 2 | 5 | 5 |
| 10 | Products in the catalogue | 2 | 1 | 5 | 5 |
| 11 | Forklift utilisation | 2 | 3 | 2 | 2 |
| 12 | Store energy per m² | 2 | 3 | 2 | 3 |

In F1 type `Score`, and in F3 the weighted sum of the row:

```localised
=SUMPRODUCT(B$2:E$2,B3:E3)      46
```

`SUMPRODUCT` multiplies the two ranges cell by cell and adds the products: here 3×5 + 3×5 + 2×4 +
2×4, which is 46. Copy
F3 down to F12. The `$` keeps every row multiplying by the weights in row 2. The best possible score
is 50.

Your column should read 46, 43, 39, 41, 39, 38, 32, 29, 23 and 25. **The top five are delivered on
promise (46), damaged deliveries (43), days of stock (41), and stock-outs and picking errors (39
each).** Delivery cost per order misses by one point, at 38.

## What the score is for

**The sheet does not choose; it makes the argument visible.** Every number in columns B to E is
somebody's judgement, and a one-point gap between the fifth and the sixth is well inside how much
two people's judgements differ. What the table gives Caio is a place to disagree with one cell
rather than with the whole page: "picking errors is a 3 on data, not a 4" is a conversation that
ends; "I think it should be there" is one that does not.

Two checks are worth making before trusting the cut. The first is whether the weights decide it.
Change the data weight in D2 from 2 to 1 and the scores move, but the same five stay on top, three of
them now tied at 36; a cut that survives a change of weights is sturdier than one that does not. The
second is the look at the bottom: **pallets received and products in the catalogue score 5 on data
and cheapness, and those two columns are all they have.** A scoring sheet without the relevance
weight would have promoted exactly the numbers that are easy to get.

Caio put delivery cost per order on the list of candidates to look at again in three months, with
the reason written beside it, which is the subject of the last section of this lesson.
