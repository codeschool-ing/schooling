---
title: The grain is one sentence
version: 1
---

Lesson 2 put the grain second in Kimball's four steps and moved on. It deserves a lesson, because it
is the step most often skipped, and a table built without one goes on returning numbers.

**The grain is a sentence saying what one row of a fact table is.** Not which columns it has: what
event or state in the business one row stands for. Ana's tables each have one, written as the first
comment of the file that builds them:

| table | grain |
|---|---|
| `fact_sales` | one line of an order that was not cancelled |
| `fact_inventory` | one book at one shop at one month-end count |
| `fact_fulfilment` | one online order, through its lifecycle |
| `fact_payments` | one payment |
| `fact_event_attendance` | one customer at one author's event |

Two properties make a grain sentence useful:

- **It is stated in business terms.** "One line of an order" can be checked against a till receipt.
  "One row per `order_id` and `line_no`" is a key, and a key can be unique while the rows still mean
  two different things.
- **It is the finest the source allows, unless there is a reason not to.** A line is the most
  detailed thing the till records. A table at the grain of the whole order could not say which book
  was sold, and no later query can put back detail that was summed away. Kimball calls the finest
  grain **atomic**, and recommends starting there.

Once the sentence exists, every candidate column can be tested against it. A column belongs in the
table **if it has exactly one value per row at that grain**. A book has one value per line. A
department has one value per line, through the book. The shipping fee does not, and the next section
shows what happens when it is put there anyway.
