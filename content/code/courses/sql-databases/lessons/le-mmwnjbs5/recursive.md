---
title: Walking a tree with WITH RECURSIVE
version: 2
---

Lesson 1 gave you a table that points at itself:

```sql
CREATE TABLE categories (
    id        integer PRIMARY KEY,
    name      text NOT NULL,
    parent_id integer REFERENCES categories (id)
);
```

Kitchen contains Cookware contains Pans contains Frying pans. A join gets you one level. Two joins
get you two levels, and you do not know how deep the tree is — so *"everything under Kitchen"* has
no answer in the SQL you have so far.

```sql
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 1 AS depth
    FROM   categories
    WHERE  id = 3                                     -- the anchor: where to start

    UNION ALL

    SELECT c.id, c.name, c.parent_id, t.depth + 1
    FROM   categories c
    JOIN   tree t ON c.parent_id = t.id               -- the step: one level further
)
SELECT * FROM tree ORDER BY depth, name;
```

Every recursive query has those two halves and the `UNION ALL` between them.

## What it actually does

The word "recursive" is misleading — nothing calls itself. It iterates:

```localised
round 0   the anchor runs                   → Kitchen                        (depth 1)
round 1   the step runs against round 0     → Cookware, Crockery             (depth 2)
round 2   the step runs against round 1     → Pans, Knives, Plates           (depth 3)
round 3   the step runs against round 2     → Frying pans                    (depth 4)
round 4   the step runs against round 3     → nothing, so it stops
```

Each round joins against **only what the previous round produced**, not against everything found so
far. That is why it terminates: the moment a round adds no rows, the query is finished, and the
result is every round's output stacked together.

Read that list once more if the syntax felt like magic. It is a loop with the condition written as
a join.

## Upwards is the same query turned round

```sql
WITH RECURSIVE ancestors AS (
    SELECT id, name, parent_id FROM categories WHERE id = 41
    UNION ALL
    SELECT c.id, c.name, c.parent_id
    FROM   categories c JOIN ancestors a ON a.parent_id = c.id
)
SELECT * FROM ancestors;
```

The join condition swapped sides: `a.parent_id = c.id` instead of `c.parent_id = t.id`. That gives
you a breadcrumb — this category and every category above it — and it is the same four lines.

## Depth, path, and getting the order right

`ORDER BY depth` gives you level by level, which is rarely what a person wants to read. A menu
wants each branch in one piece, and that needs a path:

```sql
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, ARRAY[name] AS path
    FROM   categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, c.parent_id, t.path || c.name
    FROM   categories c JOIN tree t ON c.parent_id = t.id
)
SELECT repeat('  ', array_length(path, 1) - 1) || name AS label
FROM   tree
ORDER BY path;
```

Sorting by the accumulated path puts every child directly under its parent, indented. MySQL and
SQLite have no array type, so there the path is a string: `t.path || '/' || c.name`, which sorts
the same way as long as no name contains the separator.

## A cycle is an infinite loop

If somebody makes category 3 the parent of category 1, which is the parent of 3, the query above
never stops. Nothing in the data model prevents it — a foreign key to the same table is perfectly
happy with a cycle, and lesson 3's constraints cannot express "no cycles".

Three defences, in order of how much you should like them:

**Carry the path and refuse to revisit.**

```sql
WHERE NOT (c.id = ANY(t.path_ids))
```

Explicit, portable, and it costs one more column.

**`UNION` instead of `UNION ALL`**, which deduplicates each round and therefore terminates. It
works, it hides the problem, and deduplicating every round is expensive on a large tree.

**PostgreSQL 14's `CYCLE` clause**, which is the tidiest where you have it:

```sql
) CYCLE id SET is_cycle USING path
SELECT * FROM tree WHERE NOT is_cycle;
```

And a fourth thing that is not a defence but is good sense: put a depth limit on it —
`WHERE t.depth < 20` — so a runaway query fails in a second rather than filling a disk. A category
tree twenty deep is a bug regardless.

## Generating rows out of nothing

The other everyday use, and it is not a tree at all:

```sql
WITH RECURSIVE days AS (
    SELECT DATE '2026-01-01' AS day
    UNION ALL
    SELECT day + 1 FROM days WHERE day < DATE '2026-01-31'
)
SELECT d.day, coalesce(sum(o.total), 0) AS revenue
FROM   days d
LEFT JOIN orders o ON o.ordered_on = d.day
GROUP BY d.day
ORDER BY d.day;
```

This is how a report gets **a row for a day on which nothing was sold**. Lesson 6 said a group with
no rows does not exist; here you manufacture the rows first and left-join the data onto them, so a
quiet Sunday shows a zero instead of vanishing from the chart. PostgreSQL has `generate_series` for
this and it is shorter; the recursive form is the one that works everywhere.

Support is universal enough to rely on: PostgreSQL, SQLite, MySQL 8 and MariaDB 10.2. PostgreSQL
and SQLite require the `RECURSIVE` keyword; MySQL requires it too, and none of them mind it being
there when the query turns out not to need it.
