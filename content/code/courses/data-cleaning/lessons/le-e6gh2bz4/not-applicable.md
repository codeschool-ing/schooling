---
title: Blanks that are answers
version: 1
---

**Before asking why a value is missing, ask whether a value should exist at all.** A large share of
the blanks in any real file are answers rather than gaps: the question did not apply, or the
system's way of saying zero, or a fact the business never needed. Separating those out first is
not tidying. It removes the noise that would otherwise hide the blanks that matter.

Three kinds turn up in Quitanda Verde's files.

**Not applicable.** A pickup has no courier and no delivery time, because nothing was delivered. In
the orders file that accounts for 5,717 blanks in `courier` and the same 5,717 in
`delivery_minutes`. These blanks are correct, and **the right treatment is to leave them blank and
to stop counting them as missing**: a completeness rule for delivery times should test deliveries,
which is how lesson 1's scorecard went from 54% to 97%.

**A blank that means zero.** The website's empty discount is a discount of nothing, the same fact
the app writes as `0`. Here the blank is a spelling, and lesson 4 replaces it with the zero it
means. Doing that is safe only because the meaning was established — by the profile in lesson 2,
which showed every blank coming from one system and every zero from the other, and by the fact that
the coupons themselves appear as values in both.

**Unknown, and harmless for most uses.** At a shop counter, a customer may give a loyalty number or
not:

```
ana@lab:~/clean$ psql -c "SELECT cliente IS NULL AS no_customer, count(*), round(avg(replace(substr(total, 4), ',', '.')::numeric), 2) AS avg_total FROM raw.store_sales GROUP BY 1"
 no_customer | count | avg_total 
-------------+-------+-----------
 f           |  8188 |     65.58
 t           | 15406 |     65.68
(2 rows)
```

Two sales in three carry no customer. **The sale happened and the buyer is unknown.** For revenue
the blank does not matter at all. For anything about customers — how often they come back, what
they buy — it matters a great deal, and the question becomes whether the identified third is like
the rest. The average ticket is the cheapest test there is: R$ 65.58 with a customer and R$ 65.68
without, which is no evidence that the two groups buy differently. It does not prove they are alike
in everything else; it fails to find a difference where the most obvious one would have been.

## Write the meaning down

Each of these is a decision, and the decision needs to live somewhere other than the analyst's
memory. A short table does it:

| column | blank means | so |
|---|---|---|
| `courier`, `delivery_minutes` on a pickup | no delivery took place | leave blank, exclude from completeness |
| `delivery_minutes` on a Rapidex delivery | the partner never reports times | leave blank; delivery times describe the own fleet only |
| `discount` on the website | zero | replace with 0 |
| `cliente` in the shops | sale without a loyalty number | leave blank; per-customer analysis covers a third of sales |
| `delivery_minutes`, own fleet, delivered | **not yet known** | the rest of this lesson |

The last row is what is left once the answers are out of the way: 441 delivered orders and 15
refunded ones from the company's own couriers, with no time and no reason in the row. Taking the
pickups and the Rapidex deliveries out of the way is what makes those 456 blanks visible at all.
