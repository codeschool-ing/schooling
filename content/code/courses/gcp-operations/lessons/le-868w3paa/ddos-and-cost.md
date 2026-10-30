---
title: DDoS protection, and what Cloud Armor costs
version: 1
---

**Google's front end absorbs the large network attacks before anything of yours sees them.** A flood of
packets aimed at the shop's load balancer address (the kind measured in hundreds of gigabits) lands on
Google's edge, which drops traffic that is not a valid connection to an application load balancer. That
protection comes with the load balancer and is not configured; nothing in the shop's policy is about it. **What
Cloud Armor adds is the attacks that look like real requests**: a well-formed `GET /products` sent a million
times a minute is valid HTTP, and only a rule that counts and refuses stops it. This section is from Google's
documentation and its pricing page, and nothing was run.

## Standard and Enterprise

Cloud Armor comes in two tiers. **Standard** is pay as you go: policies, rules and requests are charged, and
everything in this lesson is available in it. **Enterprise** adds adaptive protection (a model that learns the
normal traffic of each backend and proposes a rule when a layer-7 attack begins), threat intelligence lists
of known bad addresses, and access to Google's DDoS response team during an attack, for a monthly price per
project or per billing account.

From the pricing page, read on 30 October 2026, for globally scoped policies in the Standard tier:

| item | price | per month (730 hours) |
|---|---|---|
| a security policy | 0.006849315 USD per hour | 5.00 USD |
| a rule | 0.001369863 USD per hour | 1.00 USD |
| requests evaluated | 0.75 USD per million | |

Enterprise pay-as-you-go is 0.273972603 USD an hour per project, 200 USD a month, including two protected
resources; the annual subscription is 4.109589041 USD an hour, 3,000 USD a month, including up to 100.

## The shop's bill

One policy and three rules: 5 + 3 × 1 = 8 USD a month. Requests: the shop serves about 400,000 a day (lesson 13),
some 12 million in a month, at 0.75 USD per million, about 9 USD. So **about 17 USD a month** for the policy of
this lesson. During an attack the request charge grows with the attack, since every request evaluated is billed,
including the ones refused; a flood of 100 million requests is 75 USD. That is the case Enterprise's pricing is
designed for: its requests are included, and it offers billing protection for documented attacks.

For the shop, Standard is the right tier. Enterprise starts making sense when a business's revenue per hour of
downtime is larger than the subscription, and when somebody at three in the morning would want Google's team on
the call.
