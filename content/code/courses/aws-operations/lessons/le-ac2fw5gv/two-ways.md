---
title: Two ways to commit, and what each buys
version: 1
---

On-demand is the price of being free to stop. A team that knows it will run **at least** some amount of
compute for the next year or three can sell AWS that freedom back, and the discount is the largest one AWS
offers on compute: up to about 60% for the shop's instances, as the next section reads from the price list.
There are two instruments, and they have converged in price while staying different in what they cover.

**Reserved Instances**, RIs, are a commitment to an **instance type in a region**: one `m7g.large`, Linux,
in São Paulo, for one or three years. Every hour, if such an instance is running, it is billed at the
reserved rate. A **standard** RI is the cheapest and cannot be exchanged for another family; a
**convertible** one can be exchanged for another of equal or greater value, and costs more. RIs exist for
EC2, and in their own form for RDS, ElastiCache, OpenSearch and Redshift.

**Savings Plans** are a commitment to **a number of dollars an hour**, for one or three years: *we will
spend at least 2.50 USD an hour on compute*. Every hour, eligible usage is billed at the plan's rates until
the commitment is used up, and the rest at on-demand. Two kinds matter:

| | covers | flexibility |
|---|---|---|
| **Compute Savings Plan** | EC2 of any family, size, region and operating system; Fargate; Lambda | moves with the workload, to Graviton, to containers, to another region |
| **EC2 Instance Savings Plan** | one instance family in one region, `m7g` in São Paulo, any size | like a standard RI, but sizes and operating systems move freely |

Each kind is bought with **no upfront**, **partial upfront** or **all upfront** payment; paying earlier buys
a little more discount.

## What does not change

All of them are **billing constructs**. Nothing is reserved in the data centre; no instance changes; the
running fleet is exactly what it was, and the bill applies a lower rate to the hours the commitment
covers. And all of them are **paid whether used or not**: a commitment of 2.50 USD an hour is 2.50 USD
every hour of the term, including the hours the fleet is smaller than planned. That is the risk, and the
section on sizing is about it.
