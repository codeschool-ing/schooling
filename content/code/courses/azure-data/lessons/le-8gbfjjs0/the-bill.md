---
title: The bill: DBUs, and the machines under them
version: 1
---

**A Databricks bill has two lines for classic compute and one for serverless.** Classic compute pays
Databricks in DBUs, Databricks Units, and pays Azure for the virtual machines; serverless pays
Databricks alone, in DBUs that include the machines. The structure comes from Databricks' and
Microsoft's documentation; the prices below are **illustrative**, round numbers to do the sum with and
not anybody's price list, and nothing here was billed.

## What a DBU is

**A DBU is a unit of processing per hour, and each machine size consumes a set number of them per hour
it runs.** A larger machine consumes more DBUs an hour, and the price of one DBU depends on the kind
of compute, all-purpose, jobs, SQL or serverless, and on the workspace's tier. So the cost of an hour
of a classic cluster is, for each machine:

```
DBUs per hour of the machine × price per DBU for this kind of compute + Azure's price for the machine
```

**Both halves grow with the number of machines and with the hours**, which is why the decisions of
the previous section, job or all-purpose, auto termination, pools, are decisions about the bill.

## Quitanda's night, three ways

The cleaning notebook needs a driver and four workers for 30 minutes a night. Take, as illustrative
numbers, a machine that consumes **1 DBU an hour**, Azure's price for that machine at **0.20 USD an
hour**, and DBUs at **0.30 USD on the jobs rate** and **0.55 on the all-purpose rate**. Five machines:

| arrangement | hours a month | DBUs | DBU cost | machine cost | USD a month |
|---|---:|---:|---:|---:|---:|
| job cluster, 30 minutes a night | 5 × 0.5 × 31 = 77.5 | 77.5 | 23.25 | 15.50 | 38.75 |
| all-purpose cluster, stops after 60 idle minutes | 5 × 1.5 × 31 = 232.5 | 232.5 | 127.88 | 46.50 | 174.38 |
| all-purpose cluster, never stopped | 5 × 730 = 3,650 | 3,650 | 2,007.50 | 730.00 | 2,737.50 |

**The same half hour of work costs 38.75, 174.38 or 2,737.50 a month at these numbers**, and nothing
about the work changed. The second line pays the all-purpose rate and an idle hour a night; the third
is the cluster somebody forgot. The arithmetic is illustrative; the ratios are what the structure
guarantees, and they are the reason a nightly job belongs on a job cluster and every all-purpose
cluster has auto termination switched on.

**Serverless changes the shape, not the principle.** It bills DBUs only, at its own price per DBU,
for the time the work runs, with no start-up and no idle hour to pay for. Whether it is cheaper than
the first line depends on the two prices, which lesson 1's price sheet reads for Azure's half and
Databricks' pricing page gives for the DBUs.

## What the arithmetic leaves out

**The storage and the network are billed by Azure as they always are**: the lake's operations and
capacity from lesson 7, and the managed resource group's own storage account. And a workspace on the
`premium` tier pays the premium price for every DBU, whatever runs, which is the price of the access
controls and the catalogue of the next section.
