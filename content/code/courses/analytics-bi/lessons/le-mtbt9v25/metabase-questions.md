---
title: Metabase questions, and the join it needs to be told about
version: 1
---

Lesson 3 asked Metabase its first question. A **question** is Metabase's unit of work: a query plus
how to draw it. There are two ways to write one, and the menu at **New** offers both:

- **Question** opens the editor of lesson 3 — data, filters, summaries, groupings, chosen from lists.
  It is what makes Metabase a self-service tool: somebody who has never written SQL can ask
  "net revenue by month, for paid orders, in the South".
- **SQL query** opens a SQL editor on the same database. It is what an analyst uses when the editor
  cannot express the question, and its result can be drawn and saved like any other.

A question built in the editor can be turned into SQL at any time (lesson 3's **View SQL**), but not
back: a SQL question is opaque to Metabase, which cannot offer its columns as filters to other people
the way it can for an editor question. **Prefer the editor where it suffices**, for that reason.

## A join Metabase was not told about

Ask for net revenue by segment and the editor seems to refuse: `Orders` has no `segment`, and the
**by** list does not offer the customer's columns. Lantern's layer is made of views, and views carry
no foreign keys, so Metabase has no way of knowing that `orders.customer_id` points at `customers`.

Tell it, once, in the admin settings: **Table Metadata**, then the Lantern database, the `Orders`
table, and the field `Customer ID`. Set its semantic type to **Foreign Key** and its target to
`Customers → Customer ID`. From then on the **by** list under `Orders` offers the customer's region
and segment, and Metabase writes the join itself. Asked for the sum of net revenue by the customer's
segment, it wrote this:

```
SELECT
  "customers__via__customer_id"."segment" AS "customers__via__customer_id__segment",
  SUM("semantic"."orders"."net_revenue") AS "sum"
FROM
  "semantic"."orders"
  LEFT JOIN (
    SELECT
      "semantic"."customers"."customer_id" AS "customer_id",
      "semantic"."customers"."signed_up" AS "signed_up",
      "semantic"."customers"."state" AS "state",
      "semantic"."customers"."region" AS "region",
      "semantic"."customers"."segment" AS "segment",
      "semantic"."customers"."acquisition_channel" AS "acquisition_channel"
    FROM
      "semantic"."customers"
  ) AS "customers__via__customer_id" ON "semantic"."orders"."customer_id" = "customers__via__customer_id"."customer_id"
GROUP BY
  "customers__via__customer_id"."segment"
ORDER BY
  "customers__via__customer_id"."segment" ASC
```

Saved as `segment.sql` and run as the role Metabase uses:

```
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f segment.sql
 customers__via__customer_id__segment |    sum    
--------------------------------------+-----------
 home                                 | 690935.35
 office                               | 355821.05
(2 rows)
```

Two observations about the SQL. The join is a `LEFT JOIN` from the fact to a dimension — the safe
direction of lesson 3, one row per order kept. And the numbers agree with the layer: R$ 690,935.35
for home and R$ 355,821.05 for office, which add up to the R$ 1,046,756.40 the whole layer holds.

**Table Metadata is part of the semantic layer too.** A foreign key set there, a column hidden there,
a description written there: each is a definition that now lives in Metabase rather than in the
database, and lesson 3's question applies — would the next tool to arrive find it?
