---
title: Campaigns: what would have happened anyway
version: 1
---

Every campaign report answers a question nobody asked. "The spring campaign brought 1,512 orders
and R$ 529,200 in sales" counts the orders placed by the people who received it. **The question
the money depends on is how many of those orders the campaign caused**, and the customers who were
going to buy a hose that week anyway are in the 1,512 too.

That is **incrementality**: the sales a campaign added over what would have happened without it.
The difficulty is that "without it" never happened. Nobody can watch the same customer in the same
week both receive and not receive an email. Retail's answer is to make the comparison happen on
purpose, before the campaign starts.

## The holdout

In September 2025 Renata Sá, Varanda's marketing director, planned a two-week spring email
campaign to the 40,000 customers of the online shop: three emails and a 15% discount coupon. Lívia
asked for one change before it went out. **Ten per cent of the list, chosen at random, would receive
nothing.** Those 4,000 customers are the **holdout**, or control group, and whatever they bought in
the two weeks is the best estimate of what the other 36,000 would have bought without the campaign.

The choice must be random. Holding out the customers who had not bought for a year, because "they
would not have answered anyway", builds a control group that buys less for reasons of its own, and
the campaign then gets credit for the difference.

## The sheet

Two weeks later, the orders from each group. Type them into a new sheet, with the campaign's terms
below:

| | A | B | C |
|---|---|---|---|
| 1 | Group | Customers | Orders |
| 2 | Campaign | 36000 | 1512 |
| 3 | Holdout | 4000 | 136 |
| 4 | Average ticket | 350 | |
| 5 | Discount | 0.15 | |
| 6 | Sending cost | 3600 | |

Each group's rate of ordering, in percent:

```localised
=ROUND(C2/B2*100,2)      4.2
=ROUND(C3/B3*100,2)      3.4
```

The campaign group ordered at 4.20%, the holdout at 3.40%. **Only the difference, 0.80 points, is
the campaign's.** Applied to the 36,000 who received it:

```localised
=ROUND(B2*(C2/B2-C3/B3),0)      288
```

288 incremental orders. The other 1,224 would have come anyway, which is what the holdout's rate
predicts for 36,000 customers:

```localised
=ROUND(B2*C3/B3,0)      1224
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"One horizontal bar for the 1512 orders placed by the campaign group. The larger part, 1224 orders, is what the holdout says the group would have placed anyway; the smaller part, 288 orders, is what the campaign added.\" data-fig=\"l18-holdout\"><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">1,512 orders from the campaign group, two weeks</text><path d=\"M40.0 60.0 H558.1 V116.0 H40.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M558.1 60.0 H680.0 V116.0 H558.1 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"40.0\" y=\"60.0\" width=\"640.0\" height=\"56.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"40.0\" y=\"140.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1,224 would have happened anyway</text><text x=\"40.0\" y=\"158.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the holdout bought at 3.40%: 36,000 × 3.40%</text><text x=\"680.0\" y=\"140.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">288 caused by the campaign</text><text x=\"680.0\" y=\"158.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4.20% − 3.40% = 0.80 points</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the 15% discount went to all 1,512; the campaign changed what 288 did</text><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cost per incremental order: R$ 288, against R$ 55 per campaign order</text></svg>", "caption": "The campaign group's orders split by what the holdout shows. Most of them would have come anyway, and they were given the discount too."}
```

## What each order cost

The campaign's cost is the discount on every order placed with the coupon, plus sending. In
reais:

```localised
=C2*B4*B5+B6      82980
```

**The discount went to all 1,512 orders, including the 1,224 that needed no persuading.** That is
the cost a campaign report hides, because it divides by the wrong number:

```localised
=ROUND((C2*B4*B5+B6)/C2,1)      54.9
=ROUND((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3)),0)      288
```

R$ 55 per order is what the report said. **R$ 288 per order the campaign actually caused** is what
Varanda paid; that it matches the 288 orders is a coincidence of these numbers. On the online
shop's average ticket of R$ 350, it is 82.3% of each incremental sale, before the cost
of the goods themselves:

```localised
=ROUND((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3))/B4*100,1)      82.3
```

A garden retailer whose gross margin is anywhere near 82.3% does not exist. The campaign lost money
on every order it caused, and it would have been reported as a success.

## What the holdout cannot do alone

Two cautions keep the result honest. **The holdout is small**: 136 orders is enough to see a
difference of this size, but chance alone moves a rate measured on 4,000 customers by a few tenths
of a point. How sure a difference is, given the sizes of the groups, is the question of
`statistics` lesson 22, and a team that runs many campaigns asks it before quoting any of them.

**And some campaigns cannot hold anybody out.** A shop-window display, a television spot or a
price cut in every store reaches everyone. Retailers then compare stores that got the campaign with
similar stores that did not, or a period with the same period a year before and the stores' trend
around it. Each of those is weaker than a random holdout, and each says so in its report. What none
of them may do is count the campaign's orders and call the count its effect.

Renata's next campaign went out with the same holdout, a 10% discount instead of 15%, and only to
customers who had not bought in the last ninety days.
