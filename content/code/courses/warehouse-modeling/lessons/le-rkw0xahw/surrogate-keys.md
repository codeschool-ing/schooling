---
title: Surrogate keys, owned by the warehouse
version: 1
---

A **surrogate key** is a meaningless integer that the warehouse assigns to each row of a dimension,
and that fact tables use to point at it. `book_key`, `shop_key` and `customer_key` are all surrogate
keys. The natural key is kept beside it as an ordinary attribute, so the row can still be found by it.

Three properties make it worth the extra column.

**It is the warehouse's.** No source system can change, reuse or renumber it. A new till system, a
corrected ISBN or a merged customer record changes an attribute of the dimension row and leaves every
fact that points at it alone.

**It can be more than one per thing.** Customer 2123 has two:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT customer_key, customer_id, city, state, tier, valid_from, valid_to FROM dim_customer WHERE customer_id = 2123"
┌──────────────┬─────────────┬──────────┬─────────┬─────────┬──────────────────────────┬──────────────────────────┐
│ customer_key │ customer_id │   city   │  state  │  tier   │        valid_from        │         valid_to         │
│    int64     │    int64    │ varchar  │ varchar │ varchar │ timestamp with time zone │ timestamp with time zone │
├──────────────┼─────────────┼──────────┼─────────┼─────────┼──────────────────────────┼──────────────────────────┤
│         2621 │        2123 │ Contagem │ MG      │ reader  │ 2023-05-02 11:27:36-03   │ 2025-04-13 19:59:35-03   │
│         2622 │        2123 │ Londrina │ PR      │ reader  │ 2025-04-13 19:59:35-03   │ 9999-12-31 00:00:00-03   │
└──────────────┴─────────────┴──────────┴─────────┴─────────┴──────────────────────────┴──────────────────────────┘
```

One row for the years in Contagem, one for the time since the move, and each sale points at the row
that was true when it happened. The natural key cannot do that, because it is one value per customer.
**This is the property lesson 5 is built on**, and the reason surrogate keys are not optional in a
warehouse that keeps history.

**It is small.** The fact table carries one per row per dimension, 887,477 times over. The same
references written as an integer and as an e-mail address:

```sql
-- The same 887,477 references, kept as an integer key and as an e-mail address.
COPY (SELECT customer_key FROM fact_sales) TO 'by_key.parquet';
COPY (SELECT coalesce(c.email, '') AS customer_email
      FROM fact_sales f
      LEFT JOIN dim_customer d USING (customer_key)
      LEFT JOIN staging.customers c ON c.customer_id = d.customer_id) TO 'by_email.parquet';
```

```
ana@lab:~/wh$ duckdb wh.duckdb < key-size.sql
ana@lab:~/wh$ ls -l by_key.parquet by_email.parquet
-rw-r--r-- 1 ana ana 4129699 Oct  6 13:38 by_email.parquet
-rw-r--r-- 1 ana ana 2480761 Oct  6 13:38 by_key.parquet
```

**4,129,699 bytes against 2,480,761: the e-mail costs 66% more** for one column, compressed, and every
join compares longer strings. In a fact table with five dimension keys that difference is paid five
times.

Two rules keep surrogate keys meaningless, which is the point of them:

- **Nobody reads anything into the number.** `book_key` 581 is not the 581st book in any order a person
  would recognise. A key that encodes something, such as a shop's region in its first digit, becomes
  wrong the day the shop moves.
- **The load assigns them, and the load is the only thing that does.** Lesson 2 used `row_number()`
  over a natural order, which is enough for a table built from scratch. A dimension that grows night
  after night uses a sequence instead, so that new rows get new numbers and old rows keep theirs.

The date is the deliberate exception, from lesson 2: `20250418` means something, because a day does
not change its identity.
