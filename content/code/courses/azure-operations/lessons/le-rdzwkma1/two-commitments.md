---
title: Two ways to commit, and what each buys
version: 1
---

**Azure discounts compute you commit to in advance, in two ways that differ in what they bind you to.**

| | **reservation** | **savings plan for compute** |
|---|---|---|
| you commit to | a resource type, size family and region, such as D-series v5 VMs in `brazilsouth` | an amount per hour, in USD, across compute services and regions |
| applies to | matching usage only | any eligible compute: VMs, App Service premium plans, Container Apps, Functions premium |
| term | 1 or 3 years | 1 or 3 years |
| discount | the larger of the two | smaller, for the flexibility |
| if usage changes | exchange for another reservation within limits | applies automatically to whatever runs |

Both are applied by the hour: **an hour of commitment not matched by usage is lost**, not carried over.
That is the whole risk, and it is the reason the next section measures before buying.

A commitment has a **scope**: one resource group, one subscription, or shared across the billing account.
Shared scope uses unmatched hours wherever matching usage runs, which raises utilisation; a single
resource group keeps the cost where a team can see it. The shop uses shared scope and lesson 24's
allocation to charge it back.

Both are bought, not deployed: they are billing objects, and none was bought for this course. The rates
and percentages in this lesson are **illustrative**, round figures of a plausible shape, because the price
list was out of reach (lesson 1 section 03). Microsoft publishes the real discounts per size and region;
they vary, and a calculator with the real numbers comes before any purchase.
