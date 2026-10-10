---
title: A number can be correct and still mislead
version: 1
---

Every lesson of this course has been about getting the number right: one definition, checked against
the source, on a page that says when the data ends. This one is about what happens after. **A correct
number can still carry a false conclusion**, and the person who computed it is the one best placed to
see that and the one least likely to look, because the number checks out.

The failures in this lesson are all of that kind. None of them needs a mistake in the SQL:

| failure | the number | the false conclusion |
|---|---|---|
| a truncated scale | revenue by month | a steady rise looks like an explosion |
| percent against points | conversion, 7.37% to 6.77% | "a fall of 8%" heard as eight points |
| a small denominator | refund rate by region | one region "refunds twice as often" on four orders |
| a chosen window | growth to May 2026 | anything from +17% to +542%, by picking the start |
| Simpson's paradox | conversion by year | the site got worse while every device got better |
| survivorship | orders of early customers | the longest customers look like everybody |
| confounding | basket size with a discount | discounts seem to make people spend 2.5 times more |

Each section makes the claim with Lantern's data, shows why it is false, and ends with the question
that would have caught it. The questions are collected in the last section as a checklist for any
number about to leave your hands.

Two courses go further in directions this lesson only touches. `visualization` is about charts as
graphics: encodings, axes, colour, and the catalogue of misleading charts. `data-storytelling` is about
building an argument from a finding and presenting it to a room. This lesson stays on the analyst's side
of the table: **the checks between a query that ran and a sentence somebody will repeat.**
