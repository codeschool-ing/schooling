---
title: What is promised and what can be delivered
version: 1
---

The number in a contract is usually decided in a sales meeting, and the number the architecture can
deliver is decided by the architecture. **Nothing forces the two to agree**, and the gap between them is
where the credits of the first section get paid.

The first check is arithmetic lesson 14 already did. Its program gave the lab's data centre, with two
balancers and three web servers but one ISP link and one DNS server, an availability of 99.79990%, about
1051.7 minutes down a year on its own assumptions. A promise of 99.9% allows 525.6 minutes a year. **A
company that signs 99.9% for that design has promised half the downtime its own arithmetic predicts**,
before anything unusual happens. The serial parts multiply, and the promise can be no stronger than their
product.

## The parts you do not own

The chain includes things nobody in the company runs: the cloud provider's database, the DNS provider, the
payment gateway, the ISP. Each has an SLA of its own, and **a promise built on top of them can be no
stronger than theirs multiplied together**. A shop promising 99.99% while its database provider promises
99.9% is promising what it has not bought, and when the provider misses, the credit the shop receives is
a fraction of the provider's fee, while the credit the shop owes is a fraction of its own customers' fees.
The two do not cancel.

## Recovery is part of the architecture

Lesson 14 split availability into failing less and coming back sooner, and the second half decides which
promises are possible at all:

| promise over 30 days | the budget | what the design needs |
|---|---|---|
| 99% | 432.00 min | one server, a tested backup and a person on call |
| 99.9% | 43.20 min | redundancy for the common failures; a person can intervene about once a month |
| 99.95% | 21.60 min | automatic failover for every common failure |
| 99.99% | 4.32 min | automatic failover everywhere, no single point left, changes tested before they reach production |

The step that matters is between the second and third rows. **Above about 99.9% a month, any failure
that waits for a person breaks the promise by itself**, so every failure mode that matters has to be
handled by a machine, and every one of them has to have been seen to work.

That last part is why lessons 15 and 16 pulled cables and killed processes with a clock running rather
than trusting the configuration. A failover that has never been exercised is a hope, and the day it is
first exercised should not be the day it is needed. Teams that promise high numbers schedule that
exercise, a failover drill or a "game day", on a calm afternoon with people watching, and measure the gap
the way the ping in lesson 15 did.
