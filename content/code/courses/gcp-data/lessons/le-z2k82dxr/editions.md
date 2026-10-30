---
title: Capacity, editions and the slot-hour
version: 1
---

**Capacity pricing bills the compute instead of the bytes.** You stop paying per TiB read and pay
per **slot-hour**: one slot, one virtual CPU, for one hour. A query that reads 2 TiB with a simple
filter and one that reads 2 GiB with five joins can cost the opposite of what on demand would charge
for them, because what is billed is how hard the slots worked, not how much they read. Everything in
this section is from the pricing page, read on 2026-10-30, and from Google's documentation of
editions and reservations. None of it can be run here: reservations, assignments and commitments have
no emulator and no control plane in this lab.

## Three editions

**Capacity is bought in one of three editions**, Standard, Enterprise and Enterprise Plus, and the
edition sets both the price of a slot-hour and the features a query running on it may use. These are
the pay-as-you-go prices for São Paulo:

| southamerica-east1 | USD per slot-hour | per slot, for a 730-hour month |
|---|---|---|
| Standard | 0.062 | 45.26 |
| Enterprise | 0.093 | 67.89 |
| Enterprise Plus | 0.155 | 113.15 |

**The monthly column is the page's own**, and it is the hourly price times 730. A hundred slots for a
whole month in each edition:

```
ana@laptop:~/gcp$ python3 -c 'print(100 * 730 * 0.062, 100 * 730 * 0.093, 100 * 730 * 0.155)'
4526.0 6789.0 11315.0
```

**4,526, 6,789 and 11,315 USD a month** for a hundred slots that never stop. Nobody pays that for
capacity they do not use, and the next section is how the bill follows the work instead.

**The editions differ in what a query may do**, and Google's editions documentation lists the
differences feature by feature. Two are on the pricing page itself. **Commitments are only sold for
Enterprise and Enterprise Plus**, so Standard is pay-as-you-go and nothing else. And **BigQuery ML is
offered on capacity through Enterprise and Enterprise Plus**. Standard is the cheapest slot and the
most limited one, built for a team that runs ordinary SQL and wants a predictable ceiling on it.

## Reservations and assignments

**Slots are bought into a reservation, and a reservation is attached to projects by an assignment.**
A reservation is a named pool of capacity in one region and one edition: `quitanda-etl`, Enterprise,
in `southamerica-east1`. An assignment says which project's queries draw from it. A project with no
assignment stays on demand. So the choice of model is made per project, and a company can keep its
analysts on demand and put its nightly transformations on slots.

On Google Cloud, the reservation and the assignment are two commands, shown here as you would type
them and not run:

```sh
bq mk --reservation --location=southamerica-east1 --edition=ENTERPRISE \
  --slots=0 --autoscale_max_slots=200 quitanda-etl
bq mk --reservation_assignment --location=southamerica-east1 \
  --reservation_id=planner-dev:southamerica-east1.quitanda-etl \
  --job_type=QUERY --assignee_type=PROJECT --assignee_id=planner-dev
```

**`--slots=0` is the baseline and `--autoscale_max_slots=200` is the ceiling.** With a baseline of
zero, the reservation owns no slots until a query asks for them, and it never owns more than two
hundred. The next section is what happens between the two.

## Commitments

**A commitment buys slots for one or three years at a lower price.** The pricing page lists them for
Enterprise and Enterprise Plus, regional, at least 50 slots and in steps of 50, renewed automatically
unless set to cancel. Committed slots become the baseline of the reservations that use them, and the
page shows these prices for São Paulo, under the heading it calls resource commitments:

| southamerica-east1, USD per slot-hour | pay as you go | 1-year commitment | 3-year commitment |
|---|---|---|---|
| Enterprise | 0.093 | 0.0744 | 0.0558 |
| Enterprise Plus | 0.155 | 0.124 | 0.093 |

**A commitment is a discount on an hour you pay for whether you use it or not.** One year takes a fifth
off the Enterprise price, and three years take two fifths. The page also lists spend-based discounts
for BigQuery, a separate scheme you opt into by committing to an amount of spending rather than to a
number of slots; this course does not price them. A commitment shared across the organisation is the
page's words too: "There is no need to buy slot commitments for every project."

**Slot billing has a minimum as well.** Capacity "is billed per second with a one-minute minimum
duration by default", and a reservation can opt in to what the page calls fluid scaling, "per-second
billing with no minimum duration". It also leaves two things out. **Capacity does not cover storage**,
which is billed as in lesson 13 whatever model the queries use, and it does not cover BI Engine,
which lesson 18 prices.
