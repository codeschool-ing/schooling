---
title: Every design decision is a cost decision
version: 1
---

This lesson has treated cost as something to estimate, watch and explain. Most of it is decided earlier,
**when the design is drawn**, by choices lessons 4 to 9 made for other reasons. Each of them has a price
on the sheet, and seeing them side by side is what turns cost from a monthly surprise into a property
you choose.

| decision | lesson | what the sheet says, `sa-east-1` |
| --- | --- | --- |
| machine size | 4 | `m7i.xlarge` is 0.32130 an hour, exactly twice `m7i.large` at 0.16065 |
| processor family | 4 | `m7g.large`, on Arm, is 0.13010 against 0.16065: 19% less for the same size |
| storage kind | 5 | a TB for a month: EFS 570.00, gp3 152.00, S3 Standard 40.50 |
| storage class | 5 | S3 Glacier Flexible Retrieval is 0.00765 per GB-month, about a fifth of Standard |
| NAT or endpoint | 6 | NAT processing is 0.0930 per GB; a gateway endpoint for S3 adds nothing |
| region | 9 | `t3.medium` is 0.04160 in `us-east-1` and 0.06720 here |
| zones | 9 | a second zone doubles the machines and adds 0.02 per GB that crosses |
| functions or machines | 8 | see below |

None of these has one right answer, and **each saving is bought with something else**. Twice the machine
is twice the price, and right only when measurements say the smaller one is full. The Arm machine is
cheaper and needs software built for Arm. Glacier Flexible Retrieval is about a fifth of the price to
store, and takes minutes to hours to give the data back, and charges for doing it. Virginia is cheaper
on most lines of the sheet and is a long round trip from São Paulo, which is lesson 9's subject. Two
zones cost more than one, and a design in one zone goes down with it.

The last row is the clearest example of a crossover. A function with 512 MB running 100 ms per request
costs 0.20 per million requests plus 1,000,000 × 0.1 s × 0.5 GB × 0.0000166667 = 0.83 in GB-seconds:
about 1.03 USD per million requests. A `t3.medium` costs 49.06 a month whatever it serves. **The two are
equal at about 47 million requests a month**, roughly eighteen a second on average. Below that, lesson
8's functions are cheaper, and far cheaper at the quiet end. Above it, a machine that is busy all the
time wins, and whether one `t3.medium` could actually serve that load is a question for lesson 4's
measurements, not for the price list.

## Where this lands in your work

::: track data dba
In your work, **storage and data movement dominate the bill**, and machines are the smaller part. A
warehouse charged by the data each query scans turns a careless query into a line of the bill. A replica
in another zone pays 0.02 for every gigabyte of changes that crosses, every month. Backups kept for years
are GB-months that never stop accruing. Read lessons 5 and 9 again with the sheet beside them. The cost lines to watch are storage classes,
retention and traffic between zones, and most of them are decided in the schema and the backup policy
rather than in the machine size.
:::

::: track devops cloud-engineering
In your work, **you are the person who receives the alert**. Budgets, tags and the estimate are part of
every change you ship, not a report somebody else reads. A pull request that adds a NAT gateway adds
67.89 a month, and saying so in the description is part of the review. The `iac` course shows the next step,
where the cost of a change is estimated from the code before it is applied, so the conversation happens
before the money is spent.
:::

::: track *
Whatever you build, **a cost is a design property like latency or availability**. It can be measured,
it can be estimated before anything is built, and it is decided by the same drawings. Decide it on
purpose, write down the number you expect, and compare it with what arrives.
:::

That is the course. You can now look at a design and say what each part of it hands to a provider,
where it runs, who may touch it, how far its users are from it and what it will cost each month. And you
can read that last answer off a published price list rather than taking anybody's word for it.
