---
title: Metadata, kept beside the data
version: 1
---

**Metadata is data about data**: what a column means, what type it is, who owns it, how sensitive it
is, where it came from. Every team keeps it somewhere; the question is whether it is kept where it
stays true. A wiki page describing a table is correct on the day it is written and wrong the first
time a column is added without anybody remembering the page.

PostgreSQL already holds most of it. The catalogue knows every column and its type. `COMMENT ON` lets
a description live in the database, next to the column, versioned with the migrations that change
it. And the course has added two tables of its own: the classification of lesson 6 and the owners of
section 3.

```sql
-- What a column means, kept beside the column, where every tool can read it.
SET ROLE ipe_owner;
COMMENT ON TABLE sales.orders IS
  'One order placed on the site or in a shop. Owner: head of sales.';
COMMENT ON COLUMN sales.orders.customer_id IS
  'NULL for guest checkouts, which the old site allowed until December 2019.';
COMMENT ON COLUMN sales.orders.ordered_at IS
  'When the customer confirmed the order, in the shop''s time zone.';
COMMENT ON COLUMN sales.orders.total_cents IS
  'Total in centavos, after discounts, before delivery. Equals the payment.';
```

```sql
-- A data dictionary, generated: the catalogue, the classification, the owner
-- and the comment, for one table.
SELECT a.attname                              AS "column",
       format_type(a.atttypid, a.atttypmod)   AS type,
       cc.class,
       o.owner,
       col_description(a.attrelid, a.attnum)  AS meaning
FROM pg_attribute a
JOIN pg_class c      ON c.oid = a.attrelid
JOIN pg_namespace n  ON n.oid = c.relnamespace
LEFT JOIN gov.column_class cc
       ON (cc.table_schema, cc.table_name, cc.column_name) = (n.nspname, c.relname, a.attname)
LEFT JOIN gov.table_owners o
       ON (o.table_schema, o.table_name) = (n.nspname, c.relname)
WHERE n.nspname = 'sales' AND c.relname = 'orders' AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;
```

```
ana@lab:~/gov$ psql -f describe.sql
SET
COMMENT
COMMENT
COMMENT
COMMENT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f dictionary.sql
SET
   column    |           type           |  class   |     owner     |                                  meaning                                  
-------------+--------------------------+----------+---------------+---------------------------------------------------------------------------
 order_id    | integer                  | personal | head of sales | 
 customer_id | integer                  | personal | head of sales | NULL for guest checkouts, which the old site allowed until December 2019.
 ordered_at  | timestamp with time zone | personal | head of sales | When the customer confirmed the order, in the shop's time zone.
 status      | text                     | personal | head of sales | 
 total_cents | integer                  | personal | head of sales | Total in centavos, after discounts, before delivery. Equals the payment.
 coupon_code | text                     | personal | head of sales | 
(6 rows)
```

That output **is** the data dictionary of `sales.orders`, generated rather than written: the type
from the catalogue, the class from lesson 6, the owner from section 3, the meaning from the comment.
The comment on `customer_id` records the decision about guest checkouts, so the next analyst who
counts nulls finds the explanation in the same place as the column.

Three columns have no meaning yet — `order_id`, `status`, `coupon_code`. That is visible, which is
the point: a dictionary generated from the database shows its own gaps, where a hand-written one
just leaves them out.

## Three kinds, and where each lives

- **technical** metadata — types, keys, indexes — is in the catalogue already, and is always right;
- **business** metadata — meaning, owner, classification — goes in comments and governance tables,
  changed in the same migration as the thing it describes;
- **operational** metadata — when it was loaded, how many rows, whether the quality rules passed —
  is written by the jobs themselves, like `gov.quality_runs`.

Data catalogue products — DataHub, OpenMetadata, Collibra and others — read all three from many
databases and add search and a screen. They are worth having at scale. What they show is only as good
as what the databases hold, which is why the habit comes first and the product second.
