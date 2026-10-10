---
title: Contamination
version: 1
---

**A test is contaminated when the control group is touched by the treatment**, or when the two
groups do not act independently. The difference between them shrinks, or bends, and nothing in the
data announces it. Three kinds come up again and again.

## The same person in both groups

A visitor is a cookie, and a person can have several. Somebody who browses Panela's recipes on a
phone at lunch and orders on a laptop at night may see the old checkout on one and the new one on
the other. If they order on the laptop, the order counts for whichever group the laptop was in, and
the experience that convinced them may have been the other one. **The effect is diluted towards
zero**, because some of each group has seen both versions.

The fixes are a larger unit, such as the logged-in account where it exists, or accepting the
dilution and saying so. Measuring it is possible where some visitors log in: the share of accounts
seen with two devices in different groups is an estimate of how much of the test was mixed.

## People who talk to each other

Panela has a referral programme: a customer sends a friend a discount code. If the treatment changes
the referral page, a treated customer's friend lands in either group, and a control visitor arrives
already persuaded by a treated friend. **Effects that travel between people leak across the split.**
The same happens in marketplaces, where buyers and sellers share a pool, and in anything social.

The fix is to randomise **clusters** that do not talk to each other, such as cities or regions,
instead of individuals. It works and costs a great deal of power, because a test of twenty cities
has twenty units, not twenty thousand.

## Shared resources

If the treatment makes more people order, and the kitchen's capacity is fixed, the control group's
orders may be delayed or cancelled to make room. The treatment then looks better partly by taking
something from the control. **A difference that the test itself caused in the control is not an
effect of the treatment**, and it disappears the moment everybody gets the treatment. Watching a
guardrail on the control group, such as its delivery delays, is how this is noticed.

## What to write in the plan

The test plan of lesson 7 gets one more line: **what is the randomisation unit, and how could the
treatment reach the control group?** If the answer is "it cannot", say why. If it can, say how much
dilution is acceptable, or change the unit.
