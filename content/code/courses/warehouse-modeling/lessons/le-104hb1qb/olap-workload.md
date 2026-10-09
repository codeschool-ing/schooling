---
title: What the report needs
version: 2
---

The manager's side is **OLAP**, online analytical processing. Where a transaction touches a few
rows by key, an analytical query touches most of a table and summarises it: a total, a count, an
average, grouped by something a person cares about.

Section 07's report ran in 1.6 seconds. Ask PostgreSQL what it read to get there:

```
ana@lab:~/wh$ { echo 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)'; cat report.sql; } | psql | grep -m1 Buffers
   Buffers: shared hit=12518, temp read=14555 written=14571
```

**12,518 pages from memory**, which is about 103 MB, the whole of `orders` and `order_lines` and
their neighbours. And then `temp read=14555 written=14571`: part of the work did not fit in the
memory PostgreSQL allows one operation, so it wrote about 119 MB to temporary files on disk and
read them back. The order lookup read 11 pages. The report read more than a thousand times that,
and wrote some of it twice.

Look at what the report actually used, though. From `order_lines` it needed `quantity`,
`unit_price_cents`, `discount_cents` and the two keys to join on. From `orders`, a date and a
status. **A row store reads whole rows**, so it carried every other column through memory too.
Lesson 8 measures what that costs.

The shape of an analytical workload, then:

- **Few queries, each one large.** A dozen people asking a few questions an hour, rather than
  thousands of tills a second.
- **Reads, almost never writes.** The data arrives in a batch, and is not changed by the people
  who read it.
- **Many rows, few columns.** A total of one column over millions of rows, grouped by two or three
  others.
- **Joins to context.** A sale is a number; *who*, *what*, *where* and *when* make it a question.
- **History.** This year against last, before the promotion against after.

**Every item in that list is the opposite of the one in section 08.** A single design cannot be
best at both, so the warehouse is a second design.
