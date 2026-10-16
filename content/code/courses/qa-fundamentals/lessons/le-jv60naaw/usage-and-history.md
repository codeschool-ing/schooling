---
title: How often it is used, and where defects have been
version: 1
---

**Likelihood and impact are judgements. Usage and defect history are data, and they correct the judgements.** Two
areas with the same risk score are not equal if one is used by every customer and the other by one a month, or if one
has failed three times this year and the other never.

## Usage: test what people actually do

A defect's damage is its impact *per use* times *how many uses*. A wrong price on a rare combination hurts one customer;
a wrong price on the most common order hurts hundreds before anybody notices. John Musa, working on telephone software
at Bell Labs, called the picture of how a system is really used its **operational profile**, and argued that testing
should follow it: the most common journeys first and most thoroughly.

Cine Aurora's order records for September give a rough profile:

| what customers do | share of orders |
|---|---|
| buy one or two adult tickets for an evening session | 58% |
| buy with at least one half-price ticket | 31% |
| use the seat map on the website | 64% |
| use a coupon | 6% |
| ask for a refund | 1% |

Two things in that table change Lia's plan. The seat map, scored low on likelihood, is used by nearly two orders in
three, so a defect there would be seen by hundreds of customers in a week: it gets more time than its risk score alone
gave it. Coupons, scored high on likelihood, are used by one order in seventeen: still important, because the code is
new, but not before the price rule.

Usage data has a blind spot of its own. It shows what people do with the current system, not what they will do with a
new feature. On the first Wednesday after a promotion, a coupon used by 6% of orders might be used by 60%. A profile is
a guide to the present, and a tester asks what is about to change it.

## History: defects cluster

Defects are not spread evenly. They gather in some parts of a system, the complex parts, the hurried parts, the parts
written by somebody who left, and those parts keep producing them. This is one of the most consistently observed
patterns in software testing, and it is often described with Pareto's ratio: a small share of the modules holds a large
share of the defects.

Cine Aurora's own records over this course make the point:

| area | defects found so far | where |
|---|---|---|
| price rule | 4 | the age line, the 9:30 session, Wednesday stacking, inputs nobody mentioned |
| orders | 1 | refused orders written to the database |
| coupons | 1 | pasted codes with spaces |
| seat map, refunds, report | 0 | |

Four of six defects in one function. Even with the latest fix in place, the history says that is where the next one is
most likely, and lesson 19's relations check has just shown that one of the four, the 9:30 session, is still there.

## The trap in history

Defect history has a well-known failure: **the pesticide paradox**. Boris Beizer named it: a field sprayed with the same
pesticide every year ends up full of the insects it does not kill. Run the same tests on the same area release after
release, and they stop finding anything, not because the area is clean but because they only look where they have
already looked.

So history decides *where* to test, never *how*. The price rule gets the most hours, and some of those hours go on new
cases and exploration, not only on running the outline from lesson 17 again. A history of zero defects in the refund
button means nobody has looked yet, not that nothing is there.
