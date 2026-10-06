---
title: Hierarchies, regular and ragged
version: 1
---

A department contains subcategories, which contain categories, which contain books. A **hierarchy**
is a set of attributes where each level rolls up into the one above, and reports use it to start at a
total and drill down.

When every branch has the same depth, the hierarchy is **regular**, and the star stores it as one
column per level. The shop's tree is not regular. Walk it from the top:

```sql
-- Walk the category tree from each top-level node down, and print the path.
WITH RECURSIVE tree AS (
    SELECT category_id, name, name AS path, 1 AS depth
    FROM staging.categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.category_id, c.name, t.path || ' > ' || c.name, t.depth + 1
    FROM staging.categories c JOIN tree t ON c.parent_id = t.category_id
)
SELECT depth, count(*) AS nodes, min(path) AS example
FROM tree GROUP BY depth ORDER BY depth;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < tree.sql
┌───────┬───────┬─────────────────────────────┐
│ depth │ nodes │           example           │
│ int32 │ int64 │           varchar           │
├───────┼───────┼─────────────────────────────┤
│     1 │     4 │ Children                    │
│     2 │    15 │ Children > Early readers    │
│     3 │    22 │ Fiction > Crime > Detective │
└───────┴───────┴─────────────────────────────┘
```

Four departments, fifteen nodes at the second level and twenty-two at the third. Some branches stop
at two levels: *Comics* has *Manga* and *Graphic novels* and nothing below them. That is a **ragged**
hierarchy, and it is the common case: product catalogues, organisation charts and charts of accounts
are almost never the same depth everywhere.

There is a worse case hiding in it. *Biography* is a second-level node with a child, *Memoir*, and
books are also filed directly under *Biography* itself. A node that is both a parent and a leaf is
where most flattening code breaks.

## Flattening it

The star's answer is the one `dim_book` already gives: **a fixed number of columns, and a missing level
filled by repeating the level below it.**

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT department, subcategory, category FROM dim_book WHERE department IN ('Comics', 'Fiction') GROUP BY ALL ORDER BY ALL LIMIT 6"
┌────────────┬────────────────┬────────────────┐
│ department │  subcategory   │    category    │
│  varchar   │    varchar     │    varchar     │
├────────────┼────────────────┼────────────────┤
│ Comics     │ Graphic novels │ Graphic novels │
│ Comics     │ Manga          │ Manga          │
│ Fiction    │ Crime          │ Detective      │
│ Fiction    │ Crime          │ Nordic noir    │
│ Fiction    │ Crime          │ Thriller       │
│ Fiction    │ Fantasy        │ Epic fantasy   │
└────────────┴────────────────┴────────────────┘
```

*Manga* is its own subcategory and its own category. A report that groups by department and then
subcategory shows *Manga* once at each level, which is what a person expects, and no total is lost or
counted twice. The decision was made once, in `12_dim_book.sql`, and no report has to know the tree
was ragged.

## When flattening stops working

Flattening needs a maximum depth. A category tree with three levels is easy; an organisation chart
where a manager can be any number of levels above an employee is not, because no number of columns is
enough. The usual answer is a **hierarchy bridge**: a table with one row for every ancestor and
descendant pair, and the distance between them. "Everything under this node" is then one join, at any
depth. It is lesson 4's bridge-table idea applied to a tree, and it is worth knowing it exists; the
shop's three levels do not need one.
