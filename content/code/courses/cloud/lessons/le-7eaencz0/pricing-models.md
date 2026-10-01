---
title: "Pricing models: on demand, reserved, savings plans and spot"
version: 1
---

The hourly price in the sizing section is one way of buying the machine, and it is the most
expensive. **The same instance type has several prices, and what separates them is what you
promise the provider** in exchange: nothing, a year of use, a year of spending, or the right to take
the machine back.

## On demand: no promise

On demand is the price you pay by default. You start the instance when you want, stop it when you
want, and are billed for the time in between. Nothing is committed, so nothing is discounted. It is
the right price for anything whose future you do not know yet, and for anything that runs only
part of the time.

## Reserved: a year of this machine

A **reservation** is a promise to pay for a particular kind of instance for a term, one or three
years, whether it runs or not. In return the hourly rate drops. The sheet carries the one-year term
with nothing paid up front, for the same machine as before:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|on demand|reserved|m7i.large'
                                        sa-east-1    us-east-1
EC2, Linux, on demand, USD per hour
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
EC2, Linux, 1-year reserved, no upfront, USD per hour
  m7i.large                               0.09956      0.06668
```

In `sa-east-1` the reserved rate is 0.09956 against 0.16065 on demand. The discount is worked the
same way as any discount:

1 − 0.09956 / 0.16065 = 1 − 0.620 = 0.380, so **38% off**.

At 730 hours that is 72.68 USD a month instead of 117.27: the rate is 0.06109 an hour lower, which is 44.60 a month. The catch is
in the word *term*. You owe the reserved rate for all 8,760 hours of the year, which is 872.15 USD,
even if the instance is stopped in March and never started again. So the reservation only wins if
the machine would otherwise run for more than 62% of the year's hours, which is the same 0.620 read the other way. Below that, paying on demand for the hours you actually use is cheaper.

That is why reservations are bought for the floor of a system and not for its peaks. The two
machines that run every hour of every day are worth reserving. The four extra that a group adds
on weekday afternoons are not.

Terms of three years and payment up front give larger discounts, and the sheet does not read those
lines; this course only quotes what it can show.

## Savings plans: a year of spending

A reservation names a machine, and a year is long enough for the right machine to change. A
**savings plan** commits to an amount of spending per hour instead, for one or three years, and the
discount applies to whatever you run that matches the plan. The broadest kind on AWS covers any
instance family, size and region, and some serverless compute too, so moving from `m7i` to `m7g`
halfway through the year does not waste the commitment. The discount is somewhat smaller than a
reservation for one fixed type, and the flexibility is what it buys. The shape of the promise is
the same: you pay the committed amount every hour, used or not.

## Spot: the provider may take it back

A provider's hosts are never full, and **spot** sells the spare capacity at a discount that moves
with how much of it there is. The price for that discount is that the provider can reclaim the
instance when it needs the capacity back; AWS gives two minutes' warning before it does. Work that
can be interrupted and resumed fits: batch jobs that checkpoint, test runners, a video queue where a
lost job is simply retried. A database, or the only copy of anything, does not.

The spot price is not on the sheet: the public price list this
course reads does not carry it, because it changes with supply rather than being published as a
list. So this course quotes no spot figure, and the figure below draws it without one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Bars for one m7i.large in sa-east-1 for 730 hours: on demand 117.27 US dollars, one-year reserved with no upfront 72.68 US dollars, and spot drawn as a dashed band with no number because its price varies and is not in the price list.\"><defs><marker id=\"price-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">one m7i.large, sa-east-1, Linux, 730 hours</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">On demand</text><rect x=\"190\" y=\"46\" width=\"420\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">117.27 USD</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1-year reserved</text><text x=\"20\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no upfront</text><rect x=\"190\" y=\"102\" width=\"260\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">72.68 USD</text><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Spot</text><rect x=\"190\" y=\"164\" width=\"480\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"430\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">varies with spare capacity; not in the price list</text><path d=\"M190 34 L190 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "The same machine for the same month, bought three ways. The first two bars are 730 hours times a line of the price sheet. Spot has no bar length because it has no fixed price: it moves with spare capacity, and the public list does not carry it.", "same": ["Spot"]}
```

Real systems mix all three. A group can keep its minimum on reserved or savings-plan pricing, add
on-demand machines for the daily peak, and run the work that can be interrupted on spot. Lesson 10
comes back to this as a budget; what this section needs you to hold is that each discount is paid
for with a promise, and a promise you cannot keep is a cost, not a saving.
