---
title: A fact table with no facts
version: 1
---

Ponto Final holds author events on Saturdays. Customers come; nobody pays. The business process is
**attending an event**, the grain is one row per customer per event, and when step 4 asks for the
measures there are none. Nothing was measured; something *happened*.

It still gets a fact table:

```sql
-- Grain: one row per customer at an author's event. There is no measure:
-- the row is the fact.
CREATE TABLE fact_event_attendance AS
SELECT d.date_key, s.shop_key, e.author_id, ea.customer_id
FROM staging.event_attendance ea
JOIN staging.events e USING (event_id)
JOIN dim_date d ON d.date = e.held_on
JOIN dim_shop s ON s.shop_id = e.shop_id;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fact_attendance.sql
```

This is a **factless fact table**: keys and nothing else. The row is the fact. Counting rows answers
the questions:

```sql
SELECT s.shop_name,
       count(DISTINCT f.date_key)    AS events,
       count(*)                      AS attendances,
       count(DISTINCT f.customer_id) AS people
FROM fact_event_attendance f JOIN dim_shop s USING (shop_key)
GROUP BY ALL ORDER BY attendances DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < events.sql
┌───────────┬────────┬─────────────┬────────┐
│ shop_name │ events │ attendances │ people │
│  varchar  │ int64  │    int64    │ int64  │
├───────────┼────────┼─────────────┼────────┤
│ Cambuí    │     26 │         685 │    675 │
│ Savassi   │     24 │         646 │    613 │
│ Paulista  │     22 │         537 │    534 │
│ Pinheiros │     20 │         449 │    443 │
│ Batel     │     20 │         392 │    377 │
│ Moinhos   │      8 │         214 │    212 │
└───────────┴────────┴─────────────┴────────┘
```

Cambuí ran the most events and drew the most people. The gap between `attendances` and `people` is
repeat visits: at Cambuí, 685 attendances came from 675 people. None of those numbers is stored
anywhere; each is a count of rows.

## The other use: what did not happen

Kimball's second kind of factless table records **coverage**: which things were *eligible* for
something, whether or not anything happened. Which books were on promotion in each shop on each day,
for example. A sales table alone cannot say which promoted books sold nothing, because a book that did
not sell has no row in it. A coverage table has a row for every promoted book, and *coverage minus
sales* is the list of books the promotion did not move.

Ponto Final's promotions apply to whole departments, so Ana can work that list out from
`dim_promotion` and `dim_book` without one. **The moment a promotion covers a hand-picked list of
titles, the list itself becomes a fact table**, because there is no other place to write down which
titles were on it.
