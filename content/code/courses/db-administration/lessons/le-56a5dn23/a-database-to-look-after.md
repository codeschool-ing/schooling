---
title: A database to look after
version: 1
---

A server with nothing in it has nothing to administer. From this lesson on, the course looks after
one database, called **`shop`**: a shop's customers and their orders. It is small enough to make in
a quarter of a minute and big enough that its files have sizes worth reading — a million orders.

The whole of it is one file of SQL. Save it in your home directory on the server as `shop.sql`; the
easiest way is to open an editor with `nano shop.sql`, paste, and save with Ctrl+O and Ctrl+X.

```sql
-- shop.sql: the course's database. Run it with: psql shop -f shop.sql
CREATE TABLE customers (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      text NOT NULL UNIQUE,
    name       text NOT NULL,
    country    text NOT NULL,
    created_at timestamptz NOT NULL
);

CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id bigint NOT NULL REFERENCES customers (id),
    status      text NOT NULL,
    total_cents integer NOT NULL,
    created_at  timestamptz NOT NULL
);

CREATE INDEX orders_customer_id ON orders (customer_id);
CREATE INDEX orders_created_at ON orders (created_at);

-- 50,000 customers and a million orders, made by arithmetic rather than
-- random(), so every run of this file makes exactly the same rows.
INSERT INTO customers (email, name, country, created_at)
SELECT 'customer' || i || '@example.com',
       'Customer ' || i,
       (ARRAY['BR', 'PT', 'AR', 'MX', 'ES'])[1 + i % 5],
       timestamptz '2025-01-01 00:00-03' + (i % 365) * interval '1 day'
FROM generate_series(1, 50000) AS i;

INSERT INTO orders (customer_id, status, total_cents, created_at)
SELECT 1 + (i * 7919::bigint) % 50000,
       (ARRAY['paid', 'paid', 'paid', 'shipped', 'cancelled'])[1 + i % 5],
       500 + (i * 37) % 50000,
       timestamptz '2026-01-01 00:00-03' + (i % 240) * interval '1 day'
                                         + (i % 86400) * interval '1 second'
FROM generate_series(1, 1000000) AS i;

ANALYZE;
```

**Nothing in it is random.** Every value is worked out from the row's number: customer 7 always
lives in `AR`, order 10 always belongs to customer 29,191. That is deliberate. When
this course quotes a count, a size or a plan, your server should print the same, because it holds
the same rows.

`GENERATED ALWAYS AS IDENTITY` is the standard way to say "the database numbers these rows", and
the two `CREATE INDEX` lines give `orders` the indexes an application looking up a customer's orders
or last week's orders would need. `ANALYZE` at the end gathers the statistics the planner uses;
lesson 16 is about what happens when nobody runs it.

Make the database and run the file into it:

```
ana@db:~$ createdb shop
ana@db:~$ time psql shop -f shop.sql
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
INSERT 0 50000
INSERT 0 1000000
ANALYZE

real	0m13.972s
user	0m0.028s
sys	0m0.000s
```

`psql` echoes one line per statement, and the counts are the rows each `INSERT` made. `time` is the
shell's, and the line to read is `real`: about fourteen seconds on the recording machine. Yours may
take a little longer on a virtual machine with two processors.

Now ask the database what it holds:

```
ana@db:~$ psql shop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
Type "help" for help.

shop=# \dt+
                                    List of relations
 Schema |   Name    | Type  | Owner | Persistence | Access method |  Size   | Description 
--------+-----------+-------+-------+-------------+---------------+---------+-------------
 public | customers | table | ana   | permanent   | heap          | 4576 kB | 
 public | orders    | table | ana   | permanent   | heap          | 65 MB   | 
(2 rows)

shop=# \di+
                                               List of relations
 Schema |        Name         | Type  | Owner |   Table   | Persistence | Access method |  Size   | Description 
--------+---------------------+-------+-------+-----------+-------------+---------------+---------+-------------
 public | customers_email_key | index | ana   | customers | permanent   | btree         | 4272 kB | 
 public | customers_pkey      | index | ana   | customers | permanent   | btree         | 1112 kB | 
 public | orders_created_at   | index | ana   | orders    | permanent   | btree         | 12 MB   | 
 public | orders_customer_id  | index | ana   | orders    | permanent   | btree         | 9408 kB | 
 public | orders_pkey         | index | ana   | orders    | permanent   | btree         | 21 MB   | 
(5 rows)

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)

shop=# \q
```

`\dt+` lists the tables with their sizes and `\di+` the indexes. **The indexes on `orders` add up
to nearly as much as the table itself** — 12 MB, 9408 kB and 21 MB against 65 MB — which is normal
and worth remembering the next time somebody proposes a fifth index. The `+` is what adds the
`Size` column; without it the commands only list names.

That is the database the rest of the course looks after. If you ever want it back exactly as it
was, drop it and run the same two commands again:

```sh
dropdb shop
createdb shop
psql shop -f shop.sql
```
