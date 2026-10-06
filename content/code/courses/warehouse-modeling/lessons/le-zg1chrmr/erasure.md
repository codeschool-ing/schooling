---
title: Erasing a person and keeping the sales
version: 1
---

Article 18 of the LGPD lists the rights a person has over their data, among them **anonymisation and elimination**.
Article 16 lists what a company may keep anyway, such as what a legal or regulatory obligation requires. For a shop
that means a familiar tension: the sale happened, the tax records of it must be kept, and the customer may still ask
to be forgotten.

The classification says where the person is. Customer 19 has three versions in `dim_customer`, and six lines of sales:

```
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT customer_key, customer_id, name, tier, city, state, valid_from FROM dim_customer WHERE customer_id = 19"
┌──────────────┬─────────────┬──────────────────┬─────────┬──────────────┬─────────┬──────────────────────────┐
│ customer_key │ customer_id │       name       │  tier   │     city     │  state  │        valid_from        │
│    int64     │    int64    │     varchar      │ varchar │   varchar    │ varchar │ timestamp with time zone │
├──────────────┼─────────────┼──────────────────┼─────────┼──────────────┼─────────┼──────────────────────────┤
│           27 │          19 │ Gabriela Barbosa │ reader  │ Porto Alegre │ RS      │ 2021-06-18 16:45:20-03   │
│           28 │          19 │ Gabriela Barbosa │ regular │ Porto Alegre │ RS      │ 2022-04-04 18:48:13-03   │
│           29 │          19 │ Gabriela Barbosa │ patron  │ Porto Alegre │ RS      │ 2023-04-21 11:15:26-03   │
└──────────────┴─────────────┴──────────────────┴─────────┴──────────────┴─────────┴──────────────────────────┘
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT count(*) AS lines, sum(net_cents) AS net_cents FROM fact_sales WHERE customer_key IN (SELECT customer_key FROM dim_customer WHERE customer_id = 19)"
┌───────┬───────────┐
│ lines │ net_cents │
│ int64 │  int128   │
├───────┼───────────┤
│     6 │     73630 │
└───────┴───────────┘
```

```sql
-- Customer 19 asked to be erased. Every version loses what identifies the
-- person; the keys stay, so the sales still add up and point at nobody.
UPDATE dim_customer
SET customer_id = NULL, name = 'Erased on request', tier = 'erased',
    city = 'Erased', state = '--'
WHERE customer_id = 19;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < erase.sql
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT customer_key, customer_id, name, tier, city, state, valid_from FROM dim_customer WHERE customer_key IN (SELECT DISTINCT customer_key FROM dim_customer WHERE name = 'Erased on request')"
┌──────────────┬─────────────┬───────────────────┬─────────┬─────────┬─────────┬──────────────────────────┐
│ customer_key │ customer_id │       name        │  tier   │  city   │  state  │        valid_from        │
│    int64     │    int64    │      varchar      │ varchar │ varchar │ varchar │ timestamp with time zone │
├──────────────┼─────────────┼───────────────────┼─────────┼─────────┼─────────┼──────────────────────────┤
│           27 │        NULL │ Erased on request │ erased  │ Erased  │ --      │ 2021-06-18 16:45:20-03   │
│           28 │        NULL │ Erased on request │ erased  │ Erased  │ --      │ 2022-04-04 18:48:13-03   │
│           29 │        NULL │ Erased on request │ erased  │ Erased  │ --      │ 2023-04-21 11:15:26-03   │
└──────────────┴─────────────┴───────────────────┴─────────┴─────────┴─────────┴──────────────────────────┘
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT sum(net_cents) AS net_cents FROM fact_sales"
┌────────────┐
│ net_cents  │
│   int128   │
├────────────┤
│ 9574389852 │
└────────────┘
```

The update overwrites the personal columns of every version, and leaves the keys alone. **The facts were not touched**:
the six lines still point at keys 27, 28 and 29, so every total in the warehouse is what it was, 9,574,389,852
centavos, and the lines now belong to a customer nobody can name.
What gives an identifier its meaning is erased; the identifier stays.

Three things this does not do, and each one matters:

- **It does not touch the copies.** The extract files, the staging schema, the lake's Delta files and their old versions,
  the backups: each still holds the person until it is rebuilt, vacuumed or expired. Lesson 10 met this as the reason a
  Delta table's history is a liability as well as a feature. The classification has to cover them too.
- **It keeps the version dates.** `valid_from` still records three moments when this customer's tier changed. Whether three
  timestamps can lead back to a person is exactly the question article 12 asks of anonymised data, whether it can be
  reversed with reasonable effort, and it is a judgement for whoever answers for the data, not for a script.
- **It does not stop the next load.** Unless the source system has erased the customer too, tomorrow's load brings them
  back. Erasure has to start at the source, or be recorded somewhere the load reads.
