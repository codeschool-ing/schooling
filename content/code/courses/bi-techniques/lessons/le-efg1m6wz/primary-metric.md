---
title: One primary metric
version: 1
---

**A test is decided by one number, chosen before it starts.** That number is the **primary metric**.
Watching ten numbers and picking the one that moved is the commonest way a test produces a result
that does not repeat, for the reason lesson 11 measures.

A good primary metric has four properties, and they pull against each other.

| property | the question | Panela's checkout test |
|---|---|---|
| **relevant** | if it moves, does the business care? | a first order is revenue and a customer |
| **sensitive** | can the change plausibly move it within the test? | the checkout is where the order is placed, so yes |
| **attributable** | is it measured on the unit that was randomised? | randomised per visitor, measured per visitor |
| **timely** | does it arrive within the test's weeks? | the order is placed in the same visit |

So the primary metric is **conversion: the share of visitors who place a first order**, counted per
visitor.

## Why not revenue, or retention

Revenue per visitor is more relevant and far less sensitive: it carries the size of every box and
every discount, so its noise is much larger and the test would need many more visitors to see the
same change. Retention after three months is the most relevant of all, and it arrives three months
too late for a test of a few weeks. Both are good **secondary metrics**: reported, not used to
decide.

The pull between relevant and sensitive is permanent. The usual answer is a sensitive primary metric
with a well-understood link to the relevant one, here that a first order leads, on average, to the
cohorts of lessons 12 and 13.

## The unit of analysis

**The metric is counted on the same unit the test randomised.** Panela randomises visitors, so
conversion is orders divided by visitors, each visitor counted once. Counting sessions instead, with
a visitor who came back three times counted three times, makes the groups' observations depend on
each other and the arithmetic of lesson 10 wrong. Lesson 9 returns to it, because choosing the unit
also decides how the test can be contaminated.
