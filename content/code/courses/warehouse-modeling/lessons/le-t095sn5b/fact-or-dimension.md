---
title: Is it a fact or a dimension?
version: 1
---

Most tables sort themselves: a sale is a fact, a book is a dimension. A few do not, and the wrong
choice is expensive to undo, because every report is written against it. Three tests settle most
arguments.

**Does it happen, or does it describe?** An event has a date and happens again tomorrow; a
description is true of something for a while. A sale happens. A shop's city describes the shop.

**Would you sum it, or group by it?** A price charged on a line is a measure: it is summed, at
the grain of the line. A book's list price is an attribute of the book: it is used to filter and
group ("books under R$ 50"), and summing it across books means nothing.

**Does it grow with activity or with the number of things?** A fact table gets longer every day the
business trades. A dimension gets longer only when there is a new thing to describe.

## The one that looks like a fact

The shop's database has a table with a timestamp on every row, and it grows every day:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT field, count(*) AS changes FROM staging.customer_changes GROUP BY ALL ORDER BY changes DESC"
┌─────────┬─────────┐
│  field  │ changes │
│ varchar │  int64  │
├─────────┼─────────┤
│ tier    │    7686 │
│ city    │    1624 │
│ email   │     825 │
│ state   │     622 │
│ name    │     508 │
└─────────┴─────────┘
```

`customer_changes` has the shape of a transaction table: an event, a date, one row each time. **It
is not a business process anybody measures**, though. Nobody asks for "tier changes per month" in a
report. What people ask is how much a *patron* spends, or how much was sold to customers in Paraná
— and to answer either correctly for last year they need to know what tier and which state each
customer was in **at the time of each sale**.

So these 11,265 rows are the history of a dimension, not a fact. They go into the customer dimension,
as one version of each customer per period during which nothing tracked changed, and lesson 5 builds
exactly that. A warehouse that loaded them as a fact table would answer "how many customers moved",
which nobody asked, and still could not answer "where did they live when they bought", which
everybody does.

**The test that decides it: what will people put in the `WHERE` and the `GROUP BY`, and what will
they put inside `sum()`?** The first is a dimension. The second is a fact.
