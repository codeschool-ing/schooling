---
title: Covering indexes, where the table is never touched
version: 1
---

The first section left a thread hanging. Using an index is two steps: find the entry, then follow
its pointer to fetch the row. That second step is a random read, and on a query returning many rows
it is most of the cost.

A **covering index** is one that contains every column the query needs, so the second step never
happens.

```sql
CREATE INDEX ON orders (customer_id, placed_at);

SELECT customer_id, placed_at FROM orders WHERE customer_id = 2;
```

Both columns asked for are in the index. The database walks the run of entries for customer 2 and
returns them — the `orders` table is never read. PostgreSQL calls this an **index-only scan**, and
it shows up under that name in the plan.

Add one column and it is gone:

```sql
SELECT customer_id, placed_at, total FROM orders WHERE customer_id = 2;
```

`total` is not in the index, so every entry now needs its row fetched. Same index, same `WHERE`,
several times the work — and the only difference is a column in the `SELECT` list, which is not
where anybody looks for a performance change.

Which is the practical lesson, and it is lesson 4's argument arriving with a number attached:
**`SELECT *` cannot be covered by anything.** Asking for columns you do not need is not only
bandwidth; it can be the difference between reading an index and reading a table.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Two panels holding the same index on customer_id and placed_at. On the left, the query asks for those two columns: the index block is lit, the orders table beside it is dim and unvisited, and a note reads that the second step never happens — an index-only scan. On the right, the query asks for every column: an arrow leads from the index to the table, which is highlighted, with a note that this is one random read per row and on many rows it is most of the cost.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The same index, and the same rows. What differs is whether the query asks for a column the index does not hold.</text><rect x=\"14\" y=\"42\" width=\"330\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">every column asked for is in the index</text><text x=\"30\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT customer_id, placed_at</text><rect x=\"30\" y=\"98\" width=\"140\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">index</text><text x=\"100\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">customer_id,</text><text x=\"100\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">placed_at</text><rect x=\"204\" y=\"98\" width=\"124\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"266\" y=\"125\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">the orders table</text><text x=\"179\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">the second step never happens — an index-only scan</text><rect x=\"376\" y=\"42\" width=\"330\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">one column is not</text><text x=\"392\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT *</text><rect x=\"392\" y=\"98\" width=\"140\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">index</text><text x=\"462\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">customer_id,</text><text x=\"462\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">placed_at</text><rect x=\"566\" y=\"98\" width=\"124\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"125\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">the orders table</text><path d=\"M536 125 L562 125\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M562 125 L555 121 L555 129 Z\" fill=\"var(--amber)\"></path><text x=\"541\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">one random read per row, and on many rows it is most of the cost</text><text x=\"14\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A covering index is not a kind of index. It is a relationship between one index and one query, and adding a column to the SELECT can end it.</text></svg>", "caption": "The dashed arrow from lesson 9's first figure is the one this removes. Which is also why SELECT * quietly undoes it."}
```

## `INCLUDE`, for columns you only want to return

There is a tension. To cover the query above you would have to index `total` as well:

```sql
CREATE INDEX ON orders (customer_id, placed_at, total);
```

But `total` is not something you search or sort by. Putting it in the key makes the index bigger,
makes every comparison compare three values, and implies a sort order nobody wants.

PostgreSQL 11 and later, and SQL Server before it, separate the two jobs:

```sql
CREATE INDEX ON orders (customer_id, placed_at) INCLUDE (total);
```

`total` is stored in the index and is **not** part of the sorted key. The index still behaves as a
two-column index for every purpose in the last section — leftmost prefix, ordering, the lot — and
the query is covered.

Use `INCLUDE` for columns that appear in `SELECT` and never in `WHERE` or `ORDER BY`. Use the key
for everything you search on. Getting that split right is most of what makes a covering index worth
its size.

MySQL and MariaDB have no `INCLUDE`; there the column goes in the key or nowhere. SQLite has none
either, and the same applies.

## MySQL covers one thing for free

InnoDB stores the table itself in primary key order — a **clustered index** — and every secondary
index entry holds the primary key rather than a physical pointer.

Two consequences that surprise people coming from PostgreSQL:

**Every secondary index covers the primary key.** An index on `(customer_id)` can answer `SELECT id,
customer_id …` without touching the table, because `id` is in the entry already.

**And looking up a row is two index descents**, not one pointer follow: find the entry, read the
primary key out of it, then descend the clustered index to find the row. Which makes a wide primary
key expensive twice over — it is copied into every secondary index, and it is walked on every
lookup. It is the strongest argument for a compact primary key in MySQL specifically.

## PostgreSQL's asterisk, which matters

An index-only scan in PostgreSQL is not quite only the index. The index entry does not record
whether the row it points at is visible to your transaction — lesson 8's row versions are in the
table, not in the index. So the database consults the **visibility map**, a small structure marking
which pages contain nothing but rows visible to everybody.

If the page is marked all-visible, the entry is used as it stands. If it is not, the row has to be
fetched after all, and the index-only scan quietly becomes an ordinary one.

The visibility map is maintained by `VACUUM`. So:

> **An index-only scan on a heavily written table stops being index-only until `VACUUM` catches
> up.**

That is a real effect and it is one of the ways lesson 8's long-open transaction damages
performance rather than just disk: it holds `VACUUM` back, the map goes stale, and queries that had
been fast start fetching rows again. Nothing in the query changed.

## When to reach for one

A covering index is worth building when a query is **hot, narrow and selective**: run often, needs
few columns, and returns a small share of the table. A reporting query over most of the table does
not want one — it wants the table.

And be honest about the size. Adding two `INCLUDE` columns to an index on a hundred-million-row
table may add gigabytes, all of which competes for the same cache. The right answer is almost
always to measure the query first, which is lesson 10, and to add the columns you can prove are
needed rather than the ones the `SELECT` list happens to have today.
