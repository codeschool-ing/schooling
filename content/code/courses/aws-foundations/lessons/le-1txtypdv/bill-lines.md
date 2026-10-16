---
title: The lines of a bill
version: 1
---

**A bill is a list of lines, and every line has a type that says what kind of money it is.** The
usual picture is one line per service, EC2 so much, S3 so much. That is the summary on the bill's
first page. Underneath, an hour of one instance can be one line, two lines or three, depending on
how it was paid for. A reader who adds the wrong ones counts the same hour twice. **moto has no
bill**, so nothing here was captured. The line types below are the ones AWS documents for its Cost
and Usage Report. The amounts are the price-list rates from the section on paying for one machine,
applied to one hour.

## The types

| line type | what it is |
|---|---|
| `Usage` | usage charged at the on-demand rate |
| `DiscountedUsage` | usage covered by a Reserved Instance; its own cost is zero, because the reservation's fee carries it |
| `RIFee` | the reservation's recurring fee for the month, for every reserved hour, used or not |
| `Fee` | a one-time charge, such as a reservation's upfront payment on the day it was bought |
| `SavingsPlanCoveredUsage` | usage covered by a Savings Plan, shown at its on-demand cost |
| `SavingsPlanNegation` | the same amount with a minus sign, which cancels the line above |
| `SavingsPlanRecurringFee` | the plan's commitment for the hour, charged whether usage filled it or not |
| `SavingsPlanUpfrontFee` | a plan's upfront payment, on the day it was bought |
| `Tax` | tax on the month's charges, by the rules where the account is billed |
| `Credit` | a negative line, credits applied to the charges |
| `Refund` | a negative line, money AWS gave back |

## One hour, three ways

Take one hour of the shop's `m7i.large` in São Paulo, paid for in each of the three ways:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l14-lines\" aria-label=\"One hour of an m7i.large in sa-east-1 on the bill, paid for in three ways, at the rates of the price lists of 25 September 2026. On demand: one line, Usage, 0.16065. Under a standard Reserved Instance: two lines, DiscountedUsage at 0.00000 and this hour's share of the RIFee, 0.09956; paid 0.09956. Under a Compute Savings Plan: three lines, SavingsPlanCoveredUsage at 0.16065, SavingsPlanNegation at minus 0.16065, and SavingsPlanRecurringFee at 0.10915; paid 0.10915.\"><text x=\"125.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">on demand</text><rect x=\"20.0\" y=\"46.0\" width=\"210.0\" height=\"196.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"30.0\" y=\"62.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Usage</text><text x=\"210.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.16065</text><path d=\"M30.0 222.0 L220.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">paid for the hour</text><text x=\"210.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">0.16065</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">standard reservation</text><rect x=\"255.0\" y=\"46.0\" width=\"210.0\" height=\"196.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"265.0\" y=\"62.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DiscountedUsage</text><text x=\"445.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.00000</text><rect x=\"265.0\" y=\"114.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RIFee</text><text x=\"275.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">this hour's share</text><text x=\"445.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.09956</text><path d=\"M265.0 222.0 L455.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"275.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">paid for the hour</text><text x=\"445.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0.09956</text><text x=\"595.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">Compute Savings Plan</text><rect x=\"490.0\" y=\"46.0\" width=\"210.0\" height=\"196.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"62.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SavingsPlanCoveredUsage</text><text x=\"680.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.16065</text><rect x=\"500.0\" y=\"114.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SavingsPlanNegation</text><text x=\"680.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">-0.16065</text><rect x=\"500.0\" y=\"166.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SavingsPlanRecurringFee</text><text x=\"680.0\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.10915</text><path d=\"M500.0 222.0 L690.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">paid for the hour</text><text x=\"680.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">0.10915</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">documented line types, priced from the list; not a captured bill</text></svg>", "caption": "The same hour is one line, two or three. What was paid is the bottom of each column."}
```

On demand it is **one line**, `Usage`, at 0.16065. Covered by a standard reservation it is **two**.
A `DiscountedUsage` line records the hour and costs nothing on its own, and this hour's share of the
month's `RIFee` line is 0.09956. Covered by a Compute Savings Plan it is **three**. The
`SavingsPlanCoveredUsage` line carries the on-demand 0.16065, a `SavingsPlanNegation` of minus
0.16065 cancels it, and the `SavingsPlanRecurringFee` of 0.10915 is what was really paid.

**The negation exists so that the on-demand value stays on the bill.** Summing the covered usage
says what the hour would have cost without the plan, and summing the recurring fee says what it did
cost. The difference, 0.05150, is the hour's saving, and the bill alone is enough to compute it. The
same idea in the Cost Report is a column, the plan's effective cost on each covered line, which
lesson 15 queries.

**A commitment with nothing to cover still has its fee line.** A month in which the reserved
instance was stopped for ten days has an `RIFee` for every hour of the month and `DiscountedUsage`
for only the hours it ran. A Savings Plan hour with no eligible usage has a `SavingsPlanRecurringFee`
and nothing beside it. Those unmatched fees are the commitment that was wasted, and they are where
a reader looks first after a purchase.

## The lines that are not usage

AWS computes `Tax` on the month's charges where the account is billed, which is why a budget
includes it by default, as the `IncludeTax: true` of lesson 13 showed. `Credit` and `Refund` are
negative. They arrive as lines of their own rather than as changes to the lines they offset, so the
usage stays visible at its price. **Credits are why a bill can read zero while usage is real**, and
why lesson 13 advised a budget that leaves them out.

On a consolidated bill (lesson 3) every one of these lines also carries the account that used it and
the account that pays. So a reservation bought in one account appears as `RIFee` there, and as
`DiscountedUsage` in whichever account's instance it covered.
