---
title: What a metric is made of
version: 1
---

Every business metric, however it is named, is built from the same five parts. Written out for
finance's net revenue:

| part | what it says | net revenue |
|---|---|---|
| **measure** | the column that is added up, counted or averaged | `net_cents` |
| **aggregation** | how the rows become one number | `sum` |
| **filter** | which rows take part | `status = 'paid'`, not customer 1 |
| **time** | which date places a row in a period, and in which time zone | the order date, São Paulo |
| **owner** | who decides when the definition changes | finance |

Marketing's figure differs from finance's in two of the five: its measure is `gross_cents` and it
has no filter. That is the whole disagreement, and it fits in two cells of a table. **When two
numbers with the same name disagree, compare the parts before comparing the queries.** The parts
are short; the queries are long and hide the difference in a `WHERE` on line twelve.

The fourth part is the one nobody writes down. A row can carry several dates — an order is placed,
paid, shipped, refunded — and "revenue in March" means something different by each. Lantern's
tables have only the date the order was placed, which makes the choice for you here; a real shop
has all four, and the choice changes the number at every month's edge. The time zone is the
second half of the same part, and it gets a section of its own in this lesson.

The fifth part is not arithmetic, and it is the one that keeps the other four stable. **A
definition with no owner changes whenever somebody edits a query**, and nobody can say which
version a report used. With an owner, a change is a decision with a date on it.

## Measures and dimensions

The first two parts make a **measure**: something you add up. Everything you might break a measure
down by — the state, the segment, the channel, the month — is a **dimension**. "Net revenue by
region and month" is one measure and two dimensions, and nearly every question a business asks
of its data has that shape. The next two sections are about dimensions; the rest of the lesson is
about measures.
