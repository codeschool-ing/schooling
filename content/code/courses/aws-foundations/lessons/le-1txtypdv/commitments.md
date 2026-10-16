---
title: What a commitment buys, and when it pays
version: 1
---

**A commitment is paid for every hour of its term, used or not; on demand is paid only for the hours
that ran.** So a discount of 38% is not a saving of 38%. It is a saving if the machine runs enough
hours, and a loss if it does not. The number of hours where one turns into the other is the
**break-even**. It is the first thing to compute before buying anything, and the last column of
`terms.py` is that number.

## The break-even, in hours a month

On demand, an `m7i.large` costs 0.16065 dollars for each hour it runs. The one-year standard
reservation with no upfront costs 0.09956 for each hour of the year, whether an instance is running
or not. That is 72.68 dollars a month. The month on demand reaches 72.68 after 72.68 / 0.16065 =
**452 hours**, 62% of a 730-hour month. Below that, on demand is cheaper; above it, the reservation
is. The Compute Savings Plan's rate is higher, so its break-even is later, at **496 hours**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l14-breakeven\" aria-label=\"Dollars a month against hours run in a month, for one m7i.large in sa-east-1, from the price lists of 25 September 2026. On demand is a line rising from 0 dollars at 0 hours to 117.27 at 730 hours. The one-year standard reservation with no upfront is flat at 72.68, and the line on demand crosses it at 452 hours. The one-year Compute Savings Plan with no upfront is flat at 79.68, crossed at 496 hours. Left of the crossing, on demand is cheaper; right of it, the commitment is.\"><path d=\"M90.0 290.0 L670.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 290.0 L90.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"248.9\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"407.8\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><text x=\"566.7\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">600</text><text x=\"670.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">730</text><text x=\"380.0\" y=\"324.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hours the machine runs in a month</text><text x=\"82.0\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"82.0\" y=\"197.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"82.0\" y=\"105.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"90.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dollars a month</text><path d=\"M90.0 155.8 L670.0 155.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"97.9\" y=\"169.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">reservation, standard: 72.68</text><path d=\"M90.0 142.9 L670.0 142.9\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"97.9\" y=\"130.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Compute Savings Plan: 79.68</text><path d=\"M90.0 290.0 L670.0 73.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"666.0\" y=\"61.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">on demand: 117.27</text><path d=\"M449.1 161.9 L449.1 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"449.1\" cy=\"155.9\" r=\"4.5\" fill=\"var(--amber)\"></circle><path d=\"M484.1 148.9 L484.1 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"484.1\" cy=\"142.9\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"445.1\" y=\"278.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">452 h</text><text x=\"488.1\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">496 h</text><text x=\"288.6\" y=\"267.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--phosphor)\">on demand is cheaper</text><text x=\"582.6\" y=\"216.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">the commitment is cheaper</text></svg>", "caption": "A commitment is a flat line; on demand climbs with the hours. Where they cross is the break-even."}
```

**The break-even turns the purchase into a question about the machine's schedule.** A database that
runs all month is far past it. A build server that runs ten hours a day on 22 working days runs 220
hours. On demand that costs 220 × 0.16065 = 35.34 dollars, less than half of what the reservation
would. Staging environments that are stopped at night are the usual place where somebody buys a
reservation and wastes it.

## What a reservation is tied to

A **Reserved Instance** is a promise about one instance type, one operating system and one tenancy,
in one region. AWS's documentation describes two scopes:

- a **regional** reservation applies to a matching instance in any zone of the region, and, for
  Linux on shared hardware, to any size of the same family: a reservation for one `m7i.xlarge`
  covers two `m7i.large`, because sizes are counted in a family's units;
- a **zonal** reservation applies only in one zone, and in exchange it also reserves the capacity
  there, so an instance of that type can be started in that zone when others cannot.

It comes in two classes. You can change a **standard** reservation's zone, scope and size within its
family, and sell it to somebody else on AWS's Reserved Instance Marketplace when you no longer need
it. You can exchange a **convertible** reservation for another convertible one of equal or greater
value, in another family or for another operating system. The table in the section before this one
shows what that freedom costs, 0.10915 against 0.09956 an hour.

## What a Savings Plan is tied to

**A Savings Plan commits to dollars an hour, not to a machine.** The shop buys a one-year Compute
Savings Plan of 0.10915 dollars an hour, the rate of one `m7i.large`. In every hour of the year AWS
takes the usage the plan can cover and charges it at the plan's rates, up to 0.10915 dollars.
Anything beyond is on demand, and any part of the 0.10915 left unused in that hour is lost. The shop
might move the application to another family, to another region, or out of EC2 into containers on
Fargate or functions on Lambda. A **Compute** Savings Plan follows it, because it covers all of
those. An **EC2 Instance** Savings Plan covers one family in one region, any size and system. It is
priced like a standard reservation for that narrowness. AWS's documentation says neither kind can be
sold or exchanged once bought.

AWS's documentation also gives the order. In each hour AWS applies reservations first, and Savings
Plans after them to what is left. And it gives the tie to lesson 3. **In an organisation the
discount is shared across the consolidated bill.** A reservation or a plan bought in one account
covers matching usage in that account first, then in any other account of the organisation. The
exception is an account for which the management account has turned sharing off. That is why a shop
with six accounts buys its commitments in one place and lets them float, rather than one per
account.

How much to commit, and when to buy more, is the subject of `aws-operations` lesson 22. It is a
question of measuring the hours before promising them. The next section reads what a commitment
looks like once it is on a bill.
