---
title: One task, written down first
version: 1
---

Comparing tools on different tasks compares the tasks. So this lesson fixes one, small enough to
read in full in every tool and with enough traps in it to tell them apart:

> From `orders.csv`, count the delivered orders and add up their revenue per channel, for the year
> and for December. Remove exact repeated rows first. A negative total, a coupon bigger than the
> basket, counts as zero. December means December in São Paulo.

Every clause comes from an earlier lesson, and each one is a place where a tool can quietly differ:

- **Exact repeated rows**: the 25 copied orders of lesson 5. A tool that de-duplicates on a key
  instead of the whole row, or not at all, gets different counts.
- **Delivered**: lesson 13's rule that a cancelled or refunded order is not a sale.
- **Negative totals as zero**: lesson 9's decision for the 137 coupon orders.
- **December in São Paulo**: lesson 7's two clocks. The site writes its times in UTC with a `Z`, the
  app in local time. An order placed on the site at 22:30 on 30 November São Paulo time is written as
  1 December, and a tool that ignores the `Z` puts it in the wrong month.

One thing is deliberately left out: the seven typed totals of lesson 9. Fixing them needs the order
lines, and that would make the task about joins rather than tools. **Saying what a task leaves out
is part of writing it down**, so that three identical answers are not mistaken for three correct
ones.

The task is written in words before any code, and that is the first habit this lesson recommends
whatever the tool: **a specification a person can check, against which every implementation is
measured**.
