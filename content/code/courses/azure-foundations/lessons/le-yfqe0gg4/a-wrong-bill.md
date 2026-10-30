---
title: A bill that arrived wrong
version: 1
---

**Most bills that look wrong are right about something nobody expected, and the work is finding which
line says so.** The rare bill that is actually wrong is found the same way, by reading lines rather
than totals. **Nothing in this section was run**: it reads a real billing account's data, and the lab
has none. What follows is the shape of that data, from Microsoft's documentation and the open
specification it uses, and the questions that take a total apart.

## What a line of cost data says

Cost Management can hand over a subscription's costs line by line, one line per resource, meter and
day, and lesson 15 exports them to a file. Microsoft offers that file in **FOCUS**, the
FinOps Open Cost and Usage Specification, an open format several cloud providers share, so the column
names are not Azure's own. Five of them answer most questions about a surprising bill:

| column | what it says |
|---|---|
| `ChargeCategory` | what kind of charge the line is: `Usage`, `Purchase`, `Tax`, `Credit` or `Adjustment` |
| `ChargeFrequency` | `Usage-Based`, `Recurring` or `One-Time`: a monthly reservation payment is recurring, an up-front one happens once |
| `PricingCategory` | the price that applied: `Standard` for pay as you go, `Committed` for usage covered by a reservation or a savings plan |
| `BilledCost` | what this line contributes to the invoice, on the day it was charged |
| `EffectiveCost` | the same line amortised: a commitment's purchase spread over the usage it covered |

**`BilledCost` is lesson 13's actual cost and `EffectiveCost` its amortised cost**, as columns side by
side. On the day an up-front reservation is bought, one `Purchase` line carries its whole price in
`BilledCost`; the machines it covers then show `Committed` usage lines whose `BilledCost` is zero and
whose `EffectiveCost` is their daily share. A reservation's unused hours turn up as lines of their own,
and the specification has a column, `CommitmentDiscountStatus`, meant to mark them `Unused`. Microsoft's
documentation for one of its export schemas says that column is *currently null*, so check whether your
file fills it before relying on it.

## The bills that only look wrong

Four surprises account for most of the conversations about an Azure bill:

1. **The month is not the calendar month.** A pay-as-you-go subscription is billed for its own billing
   period, which Microsoft's documentation says may not align with the calendar month. The invoice
   then covers, say, the 14th to the 13th, while cost analysis shows the calendar month by default.
   The two totals differ and both are right.
2. **A purchase landed this month.** A reservation or a savings plan paid up front puts a year's or
   three years' price on one invoice. In `BilledCost` this month is enormous; in `EffectiveCost` it
   is ordinary. Lesson 13 advised the amortised view for exactly this.
3. **Something stopped covering something.** A reservation expired, a machine was resized out of
   the reservation's size family, a machine lost its Hybrid Benefit flag in a redeployment. Nothing
   new was created and the bill went up: the same usage moved from `Committed` to `Standard`, or
   gained a licence meter.
4. **Tax, credit and currency.** The invoice adds tax that cost analysis does not show, subtracts
   credits, and for a billing account in another currency than its prices, converts at a rate that
   moves.

## Taking a total apart

For a total that is higher than last month, the same order as lesson 13's, with one question first:

1. **Compare like with like**: the same period on both sides, and actual against actual or amortised
   against amortised.
2. **Group by `ChargeCategory`.** If the difference is a `Purchase`, it is a commitment, and the
   question is who bought it. If it is `Usage`, carry on.
3. **Group the usage by `PricingCategory`.** A move from `Committed` to `Standard` with no change in
   quantity is a commitment that stopped applying, item 3 above.
4. **Group by resource and meter**, filtered to what grew. A meter that was not there last month is a
   new kind of charge: a Windows licence, a public IP address, data leaving the region.

Then there is the bill that really is wrong: a charge for a resource that never existed, or a price
that is not the one on the list for its date. The evidence is the lines, with their resource ids and
dates, and the place to take it is a billing support request in the portal. In this format a correction to an
earlier period arrives as a new line with `ChargeClass` set to `Correction`, never as an edit to the
old one. **A bill is history, and history is corrected by adding to it.**
