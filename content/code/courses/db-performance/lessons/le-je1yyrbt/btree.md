---
title: The B-tree, and what "in order" buys
version: 1
---

When people say "add an index" they mean a B-tree, and `CREATE INDEX` without a `USING` clause
builds one. Every index `market` was born with is a B-tree, and so is the one lesson 2 added. It is
the right answer so often that it is easy to believe it is the only answer, and the rest of this
lesson is the questions it cannot take. This section is the ones it can, and the one place it
quietly refuses.

## One idea: the values, kept sorted

A B-tree is the column's values in sorted order, each with a pointer to its row, arranged as a
shallow tree so that finding any value takes a few page reads from the top. Everything it is good
at follows from **sorted**:

| question | why a sorted list answers it |
|---|---|
| `=` | find the value, read the matching entries |
| `<`, `>`, `BETWEEN` | find where the range starts, read forward until it ends |
| `ORDER BY` | the entries are already in that order, so there is nothing to sort |
| `ORDER BY … DESC` | read the same list backwards |
| `LIKE 'abc%'` | a prefix is a range: everything from `abc` up to just before `abd` |

The third and fourth rows are the ones people forget, and they are often worth more than the
first two. A query with `ORDER BY placed_at LIMIT 5` does not need to find five rows. It needs the
five **first** rows in an order, and a B-tree on that column hands them over without reading or
sorting anything else:

```
market=# EXPLAIN SELECT id, placed_at FROM orders WHERE placed_at >= '2025-12-24' ORDER BY placed_at LIMIT 5;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..0.61 rows=5 width=16)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..923.49 rows=24918 width=16)
         Index Cond: (placed_at >= '2025-12-24 00:00:00-03'::timestamp with time zone)
(3 rows)

Time: 2.600 ms

market=# EXPLAIN SELECT id, placed_at FROM orders ORDER BY placed_at DESC LIMIT 5;
                                                 QUERY PLAN                                                  
-------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..0.60 rows=5 width=16)
   ->  Index Scan Backward using orders_placed_at_idx on orders  (cost=0.43..68618.43 rows=2000000 width=16)
(2 rows)

Time: 0.657 ms
```

Both plans have a `Limit` straight on top of an `Index Scan`, and no `Sort` node anywhere. The
second one is the most recent five orders of two million, at a cost of 0.60, by walking the index
**backward** from its end. The `rows=2000000` on the scan is not what it reads. It is what it would
read if nobody stopped it, and the `Limit` stops it after five.

Keep that shape in mind: an index can serve the `ORDER BY` of a query as well as its `WHERE`, and
section 04 of this lesson ends up fixing the tag search with exactly that.

## The `LIKE 'prefix%'` catch

The table above says a B-tree answers a prefix search. Try it on `customers.email`, which has a
B-tree already, the one behind its `UNIQUE` constraint:

```
market=# EXPLAIN SELECT * FROM customers WHERE email LIKE 'user42@%';
                          QUERY PLAN                          
--------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..4783.00 rows=20 width=59)
   Filter: (email ~~ 'user42@%'::text)
(2 rows)

Time: 3.345 ms

market=# SELECT datcollate FROM pg_database WHERE datname = current_database();
 datcollate 
------------
 C.UTF-8
(1 row)

Time: 0.954 ms
```

A sequential scan of all 200,000 customers, with a B-tree on the very column sitting there. The
reason is the **collation**: the rules that decide how text sorts. `market` sorts by `C.UTF-8`,
and a database created on your machine may say `en_US.UTF-8` or `pt_BR.UTF-8`. Under a language's
collation the order of strings is not plain byte order, so "everything that starts with `user42@`"
is not guaranteed to be one contiguous stretch of the index. PostgreSQL 16 only turns a `LIKE`
prefix into a range on a B-tree whose collation is the plain `C` one, and `C.UTF-8` does not count.
The ordinary index is built with the column's collation, so the planner will not use it for `LIKE`.

The fix is an index built with an **operator class** that compares strings byte by byte,
`text_pattern_ops`:

```
market=# CREATE INDEX customers_email_pattern_idx ON customers (email text_pattern_ops);
CREATE INDEX
Time: 192.789 ms

market=# EXPLAIN SELECT * FROM customers WHERE email LIKE 'user42@%';
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Index Scan using customers_email_pattern_idx on customers  (cost=0.42..8.44 rows=20 width=59)
   Index Cond: ((email ~>=~ 'user42@'::text) AND (email ~<~ 'user42A'::text))
   Filter: (email ~~ 'user42@%'::text)
(3 rows)

Time: 0.916 ms

market=# EXPLAIN SELECT * FROM customers WHERE email LIKE '%42@example.com';
                          QUERY PLAN                          
--------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..4783.00 rows=20 width=59)
   Filter: (email ~~ '%42@example.com'::text)
(2 rows)

Time: 2.475 ms
```

Now the plan uses it, and the `Index Cond` shows the trick: `LIKE 'user42@%'` became the range
from `user42@` up to `user42A`, the next string after every possible continuation. The last query
shows the limit of the trick. A **leading wildcard**, `LIKE '%42@example.com'`, is not a range of
anything in sorted order, and no B-tree helps it. Section 05 has the index that does.

The pattern index is a second index on the same column, and it cannot replace the first: its order
is not the collation's order, so `ORDER BY email` and `<` comparisons by the collation still need
the original. Build one only for a column that really is searched by prefix.

## What the B-tree is not for

Every question in the table is about the **whole value** compared with another value: equal,
less, before, starts with. The questions the rest of this lesson takes are of a different shape:

- **does this array contain `kitchen`?** The value is a list, and the question is about one element
  inside it. Sorting whole arrays puts `{home,new}` and `{kitchen,new}` far apart and
  `{home,new}` and `{home,sale}` together, which is no help in finding every array with `kitchen`.
- **which titles look like this misspelling?** There is no order in which similar strings sit
  together.
- **which time ranges overlap this one?** Two ranges are not "less" or "greater" than each other.

Those are sections 04 and 05. Before them, the one structure that answers less than a B-tree does,
on purpose.
