---
title: Materialised views, which do store the answer
version: 1
---

```sql
CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT   date_trunc('month', ordered_on) AS month,
         sum(total)                     AS revenue,
         count(*)                       AS orders
FROM     orders
GROUP BY 1;
```

One word different from the last section and a completely different object. This one **runs the
query now and keeps the rows**. Reading it reads stored data, at the speed of a small table, however
long the query underneath took.

Which is the point: a report that aggregates ten million orders becomes a table with sixty rows in
it. You can index it, join it, and query it a thousand times an hour.

## And it is out of date from the moment it exists

Nothing updates it. An order placed a second after you created it is not in there, and will not be
until somebody says:

```sql
REFRESH MATERIALIZED VIEW monthly_revenue;
```

which re-runs the whole query and replaces the contents. That statement takes an exclusive lock —
**nobody can read the view while it refreshes**, which on a big one is minutes of a dashboard
showing nothing.

```sql
CREATE UNIQUE INDEX ON monthly_revenue (month);
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue;
```

`CONCURRENTLY` builds the new contents alongside and swaps rows in, so readers keep working
throughout. It requires a unique index — that is how it works out which rows changed — and it is
slower overall. On anything a person looks at, it is the one you want.

You can also create one empty and fill it later, which is how a deploy avoids running a
twenty-minute query while it holds a migration open:

```sql
CREATE MATERIALIZED VIEW monthly_revenue AS SELECT … WITH NO DATA;
```

Until it is refreshed, reading it is an error rather than an empty result — a small kindness, since
an empty answer would be indistinguishable from a quiet month.

## It is lesson 2's copy, so ask lesson 2's question

Lesson 2 said a stored copy is a bug with a schedule unless something keeps it true. A materialised
view is exactly that kind of copy, and the mechanism is the refresh, so the questions are:

1. **How stale may this be?** In minutes, and answered by the person who reads it, not by you.
2. **What refreshes it?** A cron job, a scheduled task, the end of an import. Name the thing.
3. **What happens when the refresh fails?** Silently serving last Tuesday's revenue as though it
   were today's is worse than an error, because nobody can see it.

The third is where these go wrong in practice. A number that is confidently wrong beats no number
for as long as nobody checks. If the view carries a `refreshed_at` column, every report can print
it, and that costs one line:

```sql
SELECT …, now() AS refreshed_at FROM orders GROUP BY 1;
```

## Where you cannot have one

PostgreSQL has materialised views. Oracle has had them for decades, with a query rewriter that will
use one automatically for a query you wrote against the base tables — which is a genuinely
different feature and worth knowing about before somebody tells you Oracle has nothing to teach.

**MySQL, MariaDB and SQLite have none.** There you build the same thing by hand: a real table, an
`INSERT … SELECT` that fills it, and a scheduled job that empties and refills it — or an
`INSERT … ON DUPLICATE KEY UPDATE` that updates only the months that changed.

That hand-built version has an advantage worth noticing even where materialised views exist. A
`REFRESH` recomputes **everything**, including four years of months that cannot possibly have
changed. A summary table you maintain yourself can update only yesterday, which is a hundred times
less work — and on a large enough table it is the difference between a nightly job that finishes
and one that does not.

## The four tools, side by side

The whole lesson, as the question each one answers:

| | stored | always current | what it is for |
|---|---|---|---|
| **derived table** | no | yes | one step of one query |
| **CTE (`WITH`)** | no | yes | naming the steps so a person can read it |
| **view** | no | yes | one definition, shared, written down once |
| **materialised view** | **yes** | **no** | an expensive answer that may be a little old |

The first three cost nothing and change no data; choose between them on readability. The fourth is
a different decision entirely, because it trades correctness-at-this-instant for speed, and that
trade is somebody's to approve rather than yours to make quietly.

And a rule that survives all four: **if a query is slow, find out why before you cache it.** A
materialised view over a query that was missing an index is a nightly job, a staleness window and a
new failure mode, bought in exchange for a problem that one `CREATE INDEX` would have removed.
Indexes are lesson 9 and finding out why is lesson 10 — in that order, and both before this
section's tool.
