---
title: Few metrics, paired, and changed with a date
version: 1
---

A team that can define a metric precisely can define a hundred, and a dashboard with a hundred
metrics is read by nobody. Three habits keep the list short and useful.

## One metric that leads, and its guardrails

Many teams name a **north star**: the one metric that best captures the value customers get, which
the rest of the work is meant to move. For a shop like Lantern it might be net revenue from
returning customers, because it grows only if people come back. The choice matters less than the
fact that there is one, so that two proposals can be compared by what they do to the same number.

A single metric invites gaming, even with nobody intending it. The observation is old enough to
have a name, **Goodhart's law**: when a measure becomes a target, it ceases to be a good measure.
A team rewarded for orders can raise orders with coupons that cost more than the orders bring. So
each target gets a **guardrail**, a second metric that must not get worse while the first improves:

| target | guardrail | what the pair prevents |
|---|---|---|
| orders | net revenue per order | buying orders with discounts |
| net revenue | refund rate | selling what customers send back |
| new customers | 90-day active customers | campaigns that bring people who never return |

The last row is not hypothetical for Lantern: November 2025's Black Friday campaign brought more new
customers than any other month, and lesson 9 measures how many of them stayed.

## Leading and lagging

Net revenue for a quarter is a **lagging** metric: by the time it is known, nothing can change it.
The share of visits that reach the checkout this week is a **leading** one: it moves first and can
still be acted on. A useful set has both, and says which is which, so nobody waits for the quarter
to learn what the week already showed.

## Changing a definition

Definitions change: finance decides refunds should be counted on the date of the refund rather
than the date of the order, or the business starts selling subscriptions and "active" has to
include them. **A change is a new version with a date, never a silent edit.** The card's `since`
row exists for that, and the old version stays readable, because last year's board report was
computed under it and somebody will compare the two. A chart that crosses the date of a change
should say so on the chart; otherwise a step in the line that is only a new definition reads as
something customers did.
