---
title: A bill is a list of SKUs
version: 1
---

**Every line of a Google Cloud bill is a SKU: one thing Google sells, at one price, in one place.** A
virtual machine is not one line. Its vCPUs are a SKU, its memory another, its disk a third, the traffic
it sends a fourth, each with its own unit and its own price per unit. Google's own pricing page for
Compute Engine says it in so many words, read on 30 October 2026: *each vCPU and each GB of memory on
Compute Engine is billed separately rather than as part of a single machine type*. Nothing in this lesson
ran against a bill; the lab has none, and the numbers in it are either Google's published rules or
arithmetic on an example price, said so where they appear.

A line of the bill, read from left to right:

| field | example | what it says |
|---|---|---|
| **service** | Compute Engine | which product |
| **SKU** | N2 Instance Core running in Sao Paulo | what exactly, and where |
| **usage** | 1,460 hour | how much, in the SKU's own unit |
| **cost** | the usage times the price | before any discount |
| **credits** | a sustained use discount, a promotion | negative amounts against that cost |
| **project**, **labels** | `planner-prod`, `team=planner` | whose it is, lessons 3 and 11 |

Two things follow. **The machine type is not on the bill**: an `n2-standard-4` appears as four vCPUs of
N2 cores and sixteen gigabytes of N2 memory, hour by hour, so a question about one machine is answered by
filtering on its labels, not by searching for its name. And **the SKU carries the region**, which is why
the same machine costs differently in São Paulo and in Iowa, and why lesson 1's network prices were quoted
per crossing.

## A bill that arrived wrong

Most surprising bills are surprising in one of a handful of ways, and the order to look in is the order
below. Each is a line somebody could have found in the console's cost table, grouped by SKU and project,
before the invoice arrived.

1. **Something is running that nobody remembers.** A machine from a demo, a load balancer from a test. The
   SKU names it; the project and its labels say whose.
2. **Something is being kept that nobody uses.** The disk of a deleted machine, a snapshot schedule, a
   static external address with nothing attached, which is charged at a higher rate than one in use.
3. **Traffic.** Egress to the internet or between regions, lesson 1, billed to the sender. It is the line
   that grows with success, and the one no single resource explains.
4. **A discount stopped.** The free trial's credit ran out, a promotion ended, or a commitment expired and
   the same machines went back to the on-demand price. Usage did not change; the credits line did.
5. **A new service was switched on.** Somebody enabled an API in a project, lesson 3, and it bills.

**The cure is the same in every case: find the SKU, find the project, read the labels.** Lesson 14 does that
with a query instead of the console, which is how it is done once a company has more than a few projects.
