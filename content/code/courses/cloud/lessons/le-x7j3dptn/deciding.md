---
title: "Deciding: a workload's traits against the models"
version: 1
---

The question "should our company be public, private or hybrid?" has no good answer, because
**a company is not a workload**. The models describe where one system runs and who shares its
hardware, and one company commonly has systems that belong in different places. The useful
question is asked per system, from its traits.

## The table

Each row is a trait a workload can have, and where that trait pushes. No single row decides; a
system has several traits at once, and the answer is where most of the weight lands.

| trait of the workload | pushes towards | because |
|---|---|---|
| spiky or unpredictable load | public | capacity for the peak is rented only while the peak lasts |
| steady load, the same for years | private, or public with a commitment | on-demand flexibility goes unused; compare against the committed price |
| personal data about people in Brazil | a region whose location fits the transfer rules | the LGPD regulates transfer abroad; the region decides where data at rest is |
| a rule that forbids shared hardware | private, community, or dedicated hosts | multi-tenancy is exactly what the rule excludes |
| tight latency to systems on premises | private, or hybrid with that part kept on premises | every crossing of the seam costs a round trip |
| a large dataset already in one place | wherever the data is | data gravity: moving it costs days and dollars |
| a team that knows one provider well | that provider, not two | two identity systems, two networks, two bills |
| a service only one provider offers | that provider, for that piece | the good reason for multi-cloud |
| nobody to run hardware | public | the forgotten costs of owning it are staff first |

## One company, worked through

A Brazilian online shop has three systems and a team of five who know one public provider.

The storefront has a quiet year and a Black Friday that brings several times the usual traffic.
Spiky, customer-facing, no special data rule: **public**, in `sa-east-1`, close to its customers.

The customer and order database holds names, addresses and purchase histories of people in Brazil.
It goes in the same region, which keeps the data at rest in São Paulo, and the team maps every
copy — backups, logs, the support tool — before assuming the question is closed.

The ERP runs the warehouse and has run on two servers in the warehouse's own rack for years. It
talks to barcode scanners on the floor and to nothing on the internet. Steady load, local
latency, hardware already paid for: **it stays on premises**, and nothing about the models says it
has to move.

The storefront needs stock levels from the ERP. That makes the arrangement **hybrid**: a VPN
between the warehouse and the region, a copy of the stock pushed to the cloud side every few
minutes, orders queued for the ERP to collect. One crossing per few minutes, not one per page.

A second provider is not on the list. No service the shop needs is missing from the first, no
customer demands another, and the team has one set of skills.

The answer is not one of the four words. It is **one word per system**, joined where they must
meet, and that is the normal result. Note, too, that the ERP's two servers are not a private cloud
by the test of the section on private cloud, and do not need to be: nobody asks them for machines.
