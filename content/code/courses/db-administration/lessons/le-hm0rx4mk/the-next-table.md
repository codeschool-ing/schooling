---
title: The table that arrives tomorrow
version: 1
---

Lesson 12 ended with every role holding exactly what it needs, and that state lasts **until the
next migration**. `GRANT ... ON ALL TABLES IN SCHEMA public` looks like a rule about the schema. It
is a loop that ran once: it found the tables that existed at that moment, granted on each of them,
and kept no memory of having done so.

The next table shows it. A migration adds refunds, run as the owner the way lesson 12 arranged:

```
shop=# SET ROLE shop_owner;
SET

shop=> CREATE TABLE refunds (
shop(>     id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
shop(>     order_id     bigint NOT NULL REFERENCES orders (id),
shop(>     amount_cents integer NOT NULL,
shop(>     created_at   timestamptz NOT NULL DEFAULT now()
shop(> );
CREATE TABLE

shop=> RESET ROLE;
RESET

shop=# \dp refunds
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | refunds | table |                   |                   | 
(1 row)
ana@db:~$ psql -h localhost -U app shop
shop=> INSERT INTO refunds (order_id, amount_cents) VALUES (1, 500);
ERROR:  permission denied for table refunds
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM refunds;
ERROR:  permission denied for table refunds
```

`\dp refunds` shows an empty access list, which for a table means **the owner and nobody else**.
The application that is about to write refunds is refused, and so is the analyst who will be asked
to report on them. Nothing failed during the migration, and nothing will fail until the first
request that touches the new table, which is in production, after the deploy, in front of a
customer.

There are three ways to answer this, and only the third keeps working:

1. **Run the `GRANT ... ON ALL TABLES` again after every migration.** It works until the day
   somebody forgets, and it grants on everything each time, including the table that was
   deliberately left out last month.
2. **Put the grants in each migration**, beside the `CREATE TABLE`. Better: the decision is written
   down where the table is. It still depends on every author remembering it, every time.
3. **Tell the server what a new table should be given**, once, before the tables exist. That is a
   default privilege, and the next section sets two.

Whichever you choose, `refunds` itself needs its grants by hand, because a default privilege is
applied when a table is created and never afterwards.
