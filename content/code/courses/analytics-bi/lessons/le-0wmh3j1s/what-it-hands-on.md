---
title: What exploration hands to the next step
version: 1
---

An exploratory analysis ends with a list, not a chart. Nobody needs to see the histogram again;
everybody who builds a number on these tables needs to know what was found. Here is Lantern's, as
it would go to the team:

| found | evidence | consequence |
|---|---|---|
| `order_lines` is one row per product in an order | 11,362 lines, 7,102 orders | count orders from `orders`, never from lines |
| order value is right-skewed | median R$ 95.80, mean R$ 170.23 | report the median beside any mean |
| two populations: home and office | medians R$ 85.80 and R$ 456.25 | split by segment before summarising |
| three lines priced 100× too high | orders 412, 415, 431 | fix at the source; until then, exclude and say so |
| customer 1 is the shop's test account | four orders of one to three cents | exclude from every sales figure |
| 14 August 2025 is missing | zero orders amid days of 5 to 15 | August 2025 totals are short |
| June 2026 is a partial month | data ends 17 June | never compare it with a whole month |
| Sundays are half a weekday | 537 orders against about 1,000 | compare a day with the same weekday |
| the discount correlation is the segment | *r* 0.271 overall, −0.005 within home | do not claim discounts raise basket size |

**Every row of that table is something a dashboard would otherwise get wrong in silence.** None of
them is visible in a single number: each was found by looking at a distribution, an extreme, a
gap or a group.

## From findings to definitions

Look at the last column. Half of it is a decision about what a number should include: refunded
orders or not, the test account or not, the partial month or not, gross value or value after the
discount. Two analysts who make those decisions differently will both be right about their own
query and will disagree about Lantern's revenue.

That disagreement is lesson 2. Before any tool draws a chart, the people who read the numbers
have to agree what each one means, and write it down where everybody reads the same sentence.
