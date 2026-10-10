---
title: Two indexes that are one
version: 1
---

A duplicate index is the cheapest win in this lesson: two indexes that store exactly the same
thing, so one of them can go and **no query anywhere can get slower**, because the planner will use
the other for everything the first did. The difficulty is only in seeing them. **Two indexes are
not duplicates because their names look alike, and they can be duplicates with names that share
nothing.** `orders_customer_id_idx` and `orders_customer_idx` happen to look related;
`order_lines_product_id_idx1` is a name PostgreSQL invented when a migration said
`CREATE INDEX ON order_lines (product_id)` without one, and the `1` on the end is the only clue
that an `order_lines_product_id_idx` already existed.

Nor is reading the definitions by eye reliable. PostgreSQL does not refuse a second index on the
same columns, and a definition in a migration file can differ in spelling from what the server
stored, while one that looks the same can differ in a way that matters. So ask the catalogue.

## What makes two indexes the same

`pg_index` has one row per index, and five of its columns together say what an index contains:

| column | what it holds |
|---|---|
| `indkey` | the table's column numbers, in index order; 0 for an expression |
| `indclass` | the operator class of each column, which also fixes the index type |
| `indcollation` | the collation of each column, which decides the order of text |
| `indexprs` | the expressions, for an index on `lower(email)` and the like |
| `indpred` | the `WHERE` of a partial index |

Two indexes on the same table that agree on all five store the same entries in the same order.
Every one of them matters. **Same columns with a different `indclass` are not duplicates**: a
B-tree and a hash index on `customer_id` answer different questions, and so do two B-trees on a
text column where one uses `text_pattern_ops` for `LIKE 'abc%'`. Same columns with different
`indpred` are not duplicates either: a partial index on the pending orders (lesson 9) holds a few
thousand entries where the full one holds two million.

The query groups `pg_index` by those five and keeps the groups with more than one member. Two of
the columns are of types that cannot be compared directly, so they are turned into text first, and
`pg_get_expr` turns the stored expression trees back into SQL:

```sh
cat > ~/duplicate-indexes.sql <<'SQL'
-- duplicate-indexes.sql: indexes on the same table that store the same
-- thing, whatever they are called: the same columns in the same order,
-- the same operator classes and collations, the same expressions and
-- the same WHERE.
SELECT indrelid::regclass AS table,
       array_agg(indexrelid::regclass ORDER BY indexrelid) AS indexes
FROM pg_index
GROUP BY indrelid, indkey::text, indclass::text, indcollation::text,
         coalesce(pg_get_expr(indexprs, indrelid), ''),
         coalesce(pg_get_expr(indpred, indrelid), '')
HAVING count(*) > 1;
SQL
```

```
ana@vm:~$ psql market -f duplicate-indexes.sql
    table    |                         indexes                          
-------------+----------------------------------------------------------
 orders      | {orders_customer_id_idx,orders_customer_idx}
 order_lines | {order_lines_product_id_idx,order_lines_product_id_idx1}
(2 rows)

Time: 2.393 ms
```

Two pairs, which is what the leftovers file built. Each array is in order of creation, so the
first name in it is the older index.

## Which one goes

Either, as far as the data is concerned: they are the same index twice. The choice is about
everything around the data, and three things decide it.

**Keep the one a constraint owns.** If one of the pair backs a primary key or a unique constraint,
it is the one that stays, because the server refuses to drop it on its own anyway. Dropping a
non-unique twin of a primary key is always safe.

**Keep the one your migrations know.** The migration history, the application's code and the next
person's memory refer to indexes by name. `orders_customer_id_idx` is in `market.sql`, which is
this database's oldest migration; `order_lines_product_id_idx1` is a name nobody chose. Keep the
names that are written down somewhere.

**Ignore which one the counters say was read.** Section 03 of this lesson showed the planner
reading `orders_customer_idx` 72,686 times and the original not at all. That records a tie the
planner broke, not a preference worth keeping: the moment the twin is gone, the same scans go to
the survivor, with the same plan. Section 06 of this lesson drops `orders_customer_idx` and
`order_lines_product_id_idx1`, and the measurement at the end of it shows nothing got slower.

## What the query does not catch

It finds indexes that are identical, which is the case a machine can settle. Two near-misses are
left for you:

- **An index and a unique constraint on the same columns.** `CREATE UNIQUE INDEX` and a plain
  `CREATE INDEX` on the same column have the same five columns in `pg_index` and the query lists
  them together; keep the unique one. If they also differ in `indclass` they will not be listed,
  and you have to read them.
- **One index that is the beginning of another.** `(seller_id)` and `(seller_id, placed_at)` are
  not the same index, and this query rightly says nothing about them. They are not independent
  either, and that is the next section.

**Run the query on every database you look after, once.** Duplicates are common, they are free to
remove, and they are the easiest way to show a team what the rest of this lesson is about, because
nobody can argue that a second copy of an index is earning its keep.
