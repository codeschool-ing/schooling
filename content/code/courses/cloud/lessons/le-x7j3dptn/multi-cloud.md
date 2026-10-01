---
title: "Multi-cloud: two providers at once"
version: 1
---

Hybrid joins a private environment to a public one. **Multi-cloud means using two or more public
providers at the same time**, and the two can combine: a company can run a datacentre, one provider
and another, all joined. The word is used for anything from one team trying a second provider's
service to an application built to run on either. The interesting case is the second, and the
question is why anybody would.

## Reasons that hold up

A service only one provider has. A particular managed database, a machine-learning service, a
data warehouse the team already knows: if the best tool for one job lives with the second provider,
using it there is an ordinary engineering choice. The rest of the estate stays where it was.

A customer's or a regulator's requirement. A large client's contract can name the provider its data
must live with, and a product sold through each provider's marketplace has to run on each of them.

An acquisition. The company bought another company, and the other company ran on the other
provider. A great deal of multi-cloud starts this way, and nobody designed it.

Negotiation. A customer who could move has something to bargain with when prices are discussed.
**The argument only works if moving is real**, which means the work of being able to move has
already been done and paid for.

## The weak reason: resilience by default

"If our provider goes down, we fail over to the other one." It sounds like the obvious insurance, and
it is the most expensive reason on the list. For it to work, every part of the application has to
run on both providers, the data has to be copied continuously between them — out of one provider at
its internet egress price, every month — and the failover has to be tested often enough that it
works on the day. An untested failover is a plan to find out during the outage.

A second region of the same provider protects against the loss of one region with **one set of
tools, one identity system and one bill**. What a second provider adds on top of that is protection
against the whole provider failing at once, and whether that risk is worth the price is a question
to answer with numbers, not by default. Lesson 9 shows what a second region involves.

## What it costs, even when the reason is good

The first cost is **the lowest common denominator**. An application that must run on both can use
only what both offer in compatible forms: virtual machines, object storage, a database engine both host. Each
provider's managed services — often the reason for being in a cloud at all — are either given up or
built twice, once per provider.

Two of everything else follows:

- two identity systems, with two models of users, roles and policies that differ in the details
  that matter (lesson 7 shows one);
- two networks, joined across the same kind of seam as a hybrid, and paying egress on each side;
- two bills, in two formats, reconciled by somebody every month;
- two sets of skills, and an on-call rota that knows both.

None of that is a reason never to do it. It is the price, and **the reason has to be bigger than
the price**. For most teams, most of the time, one provider used well is the stronger position.
