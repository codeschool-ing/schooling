---
title: Is a CTE computed once, and is it slower
version: 1
---

Somebody will tell you that `WITH` is slow. Somebody else will tell you it costs nothing. Both are
quoting a real database in a real year, and both are repeating it long after it stopped being true.
This section is what is actually going on, because the answer changes what you write.

## Two things a database can do with a named step

**Inline it.** The definition is substituted into the outer query and the planner treats the whole
thing as one query — so a filter outside can be pushed inside, an index can be used, and only the
rows that matter are ever produced.

**Materialise it.** The definition is executed on its own, the rows are stored in a temporary
result, and the outer query reads that. Nothing outside can influence what it produced.

For a derived table, engines have always inlined where they could. For a CTE, the history is
messier.

## What PostgreSQL did, and when it changed

**Before version 12, every CTE was materialised.** Always, with no way to ask otherwise. It was
known as the optimisation fence, and the consequence is easy to demonstrate:

```sql
WITH everything AS (SELECT * FROM orders)
SELECT * FROM everything WHERE id = 7;
```

On PostgreSQL 11 that reads the whole `orders` table, builds the lot in memory, and then finds one
row. The same query written with a derived table uses the index and touches one row. A million-row
table makes that the difference between a second and a millisecond.

People used the fence deliberately, too — as the one available hint. A planner making a bad choice
could be walled off by pushing part of the query into a CTE, and that was a legitimate, if
uncomfortable, technique.

**From version 12 a CTE is inlined** when it is referenced exactly once, is not recursive, and does
nothing that modifies data. Otherwise it is materialised. And you can say which you want:

```sql
WITH everything AS NOT MATERIALIZED (SELECT * FROM orders)  -- inline it
WITH everything AS MATERIALIZED     (SELECT * FROM orders)  -- compute it once, fence it off
```

Two conclusions follow, and they matter more than the history:

- **Advice about CTEs written before 2019 is about a different database.** Including advice you
  will find at the top of a search result today, because nothing on the internet is ever revised.
- **An upgrade changed the plans of queries nobody touched.** Mostly for the better. Not always:
  a query that leaned on the fence to avoid a bad plan lost the fence.

MySQL 8 does the same kind of thing by its own heuristics, merging a derived table or CTE into the
outer query where it can and materialising it where it cannot, with `NO_MERGE` as the hint to stop
it. SQLite flattens subqueries under a documented list of conditions, and a CTE referenced more than
once is materialised.

## So is it computed once?

Only when it is materialised. Take a CTE referenced twice:

```sql
WITH monthly AS (SELECT date_trunc('month', ordered_on) AS month, sum(total) AS revenue
                 FROM orders GROUP BY 1)
SELECT this.month, this.revenue, prev.revenue
FROM   monthly this LEFT JOIN monthly prev ON prev.month = this.month - INTERVAL '1 month';
```

Here PostgreSQL materialises, because inlining would mean computing the aggregate twice. So the
expensive part runs once, which is exactly what you wanted — and it is worth knowing that this is a
consequence of the rule rather than a promise `WITH` makes.

The claim to retire is the other one: **naming a step does not memoise it.** A CTE is not a
variable holding a value. It is a query, and whether it runs once or is folded into the outer query
is the planner's decision.

## What to actually do

**Write `WITH` when it reads better, which is most of the time.** On any engine you will meet
today, the readable version is the same speed or close enough that the difference is not the reason
to choose.

**When you need materialisation, say `MATERIALIZED`.** Do not rely on a version's default, and do
not use a CTE as a fence silently — somebody will rewrite it as a join, the plan will change, and
the reason it was written that way is nowhere in the file. A comment saying why is part of the fix.

**And measure rather than argue.** Every claim in this section is checkable in about a minute with
`EXPLAIN`, which is lesson 10. Until you have run it on your data, on your version, the speed of a
query is an opinion — including the speed of the query you just improved.
