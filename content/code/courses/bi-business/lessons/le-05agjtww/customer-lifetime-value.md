---
title: Customer lifetime value
version: 1
---

Ipê spends money to win every card customer: an advertisement, a commission to a partner, a fee to a
comparison site. Whether that money was well spent depends on what the customer brings in over all the
years they stay, not in the first month. **Customer lifetime value, CLV, is that sum**, and set against
the cost of acquiring the customer it says which channels are worth paying for.

## The simple version

A full CLV model discounts future money, lets retention change with the customer's age, and subtracts
expected losses customer by customer. This lesson uses the simple version, and says what it leaves out:

**CLV = annual margin per customer × expected years as a customer**

The annual margin is what a customer earns Ipê in a year after funding, losses and servicing: margin,
not revenue, because revenue a customer costs as much to serve is worth nothing. The expected years come
from retention, the share of customers still active a year later. **If 75% stay each year, a customer
stays 1 ÷ (1 − 0.75) = 4 years on average.** The formula follows from losing the same share every year;
at 90% retention it gives 10 years, and at 50% two.

This version is undiscounted: a real earned in 2030 counts the same as one earned today, which
overstates long lives. Every CLV in this section is therefore an upper bound, and the comparison between
channels is fairer than any single figure.

## By acquisition channel, in your sheet

Ipê's card customers by the channel that brought them in, with what each customer cost to acquire (CAC),
the annual margin per customer and the retention, all in reais and per cent. Type it from A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Channel | CAC | Margin | Retention % |
| 2 | Partner stores | 180 | 260 | 70 |
| 3 | Search ads | 420 | 380 | 80 |
| 4 | Comparison sites | 650 | 340 | 60 |
| 5 | Referral | 120 | 300 | 75 |

In E1 type `Years`, and in E2:

```localised
=ROUND(1/(1-D2/100),2)      3.33
```

In F1 `CLV`, and in F2 the margin times the years:

```localised
=ROUND(C2*E2,0)      866
```

And in G1 `CLV/CAC`, how many reais of lifetime value each real of acquisition buys:

```localised
=ROUND(F2/B2,1)      4.8
```

Copy E2:G2 down to row 5:

| channel | CAC | years | CLV | CLV/CAC |
|---|---|---|---|---|
| Partner stores | R$ 180 | 3.33 | R$ 866 | 4.8 |
| Search ads | R$ 420 | 5 | R$ 1,900 | 4.5 |
| Comparison sites | R$ 650 | 2.5 | R$ 850 | 1.3 |
| Referral | R$ 120 | 4 | R$ 1,200 | 10 |

## What the table says

**The most valuable customers are not the cheapest ones, and the cheapest are not the most valuable.**
Search ads bring the customers worth most, R$ 1,900 each, and cost more than twice as much as partner
stores. Comparison sites look like any other channel in a report of customers won, and they barely pay
back: R$ 650 spent for R$ 850 of margin, before discounting, whose customers leave fastest.

Referrals return ten reais for each real spent. The temptation is to move the whole budget there, and
the table cannot say whether that works: a referral channel is limited by how many customers have a
friend to refer, and the next thousand referrals will not cost R$ 120 each. It is the average-against-
next-cost point of lesson 15's paid search, again.

## Where it misleads

Retention measured on customers acquired last year is a guess about customers acquired this year, from a
channel that may have changed. And at a lender, a high-margin customer may be a high-risk one: a
customer who pays interest every month earns Ipê more than one who pays in full, right up to the month
they stop paying. **A CLV computed without the losses of the credit-risk section is a figure for the
customers Ipê wishes it had.** That is why the margin column has losses taken out, and why Fernanda's
team recomputes it by vintage, as the vintages age.
