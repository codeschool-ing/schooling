---
title: A shop worth indexing
version: 1
---

An index is invisible against five customers. Every query on lesson 1's shop returns before you
can measure it, which was the point while the subject was what a join means, and it hides
everything this lesson is about. So this lesson and the two after it run against the same shop
with **a million orders** in it.

Nobody types a million orders. This file makes them up — names drawn from two short lists,
addresses numbered `user1@example.com` upwards, prices and dates drawn at random — from a fixed
seed, so your shop and the one in the transcripts are the same rows:

```sql
-- shop-large.sql: the shop of lessons 9 to 11, with a million orders in it.
-- Every row is made up here, from a fixed seed, so two runs make the same shop.
-- Load it into an empty database:  psql shop -f shop-large.sql
SELECT setseed(0.42);

CREATE TABLE customers (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name   text NOT NULL,
    email  text NOT NULL UNIQUE,
    city   text
);

CREATE TABLE products (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku    text          NOT NULL UNIQUE,
    name   text          NOT NULL,
    price  numeric(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer       NOT NULL REFERENCES customers (id),
    placed_at   timestamptz   NOT NULL,
    total       numeric(10,2) NOT NULL CHECK (total >= 0),
    status      text          NOT NULL
);

CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products (id),
    quantity   integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

-- 100,000 customers: a first name and a surname drawn from ten each, an
-- address that is unique by construction, and one of ten cities.
INSERT INTO customers (name, email, city)
SELECT (ARRAY['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa',
              'Fábio', 'Helena', 'Igor', 'Júlia', 'Marcos'])[1 + floor(random() * 10)]
       || ' ' ||
       (ARRAY['Alves', 'Carvalho', 'Costa', 'Fontes', 'Lima',
              'Mendes', 'Oliveira', 'Ribeiro', 'Rocha', 'Santos'])[1 + floor(random() * 10)],
       'user' || n || '@example.com',
       (ARRAY['Belem', 'Belo Horizonte', 'Curitiba', 'Fortaleza', 'Manaus',
              'Porto Alegre', 'Recife', 'Rio de Janeiro', 'Salvador', 'Sao Paulo'])[1 + floor(random() * 10)]
FROM generate_series(1, 100000) AS n;

-- 1,000 products at prices between 5 and 1,000.
INSERT INTO products (sku, name, price)
SELECT 'P-' || lpad(n::text, 4, '0'), 'Product ' || n, round((5 + random() * 995)::numeric, 2)
FROM generate_series(1, 1000) AS n;

-- 1,000,000 orders over 1,000 days from 2023, more of them as the shop grows.
-- Six in ten are paid, three shipped, one cancelled, and a few still pending.
-- total is drawn on its own rather than added up from the lines: these rows
-- exist to be counted and planned, and nothing in lessons 9 to 11 adds them.
INSERT INTO orders (customer_id, placed_at, total, status)
SELECT 1 + floor(random() * 100000),
       timestamptz '2023-01-01 00:00+00' + sqrt(random()) * interval '1000 days',
       round((10 + random() * 990)::numeric, 2),
       CASE WHEN s < 0.600 THEN 'paid'
            WHEN s < 0.897 THEN 'shipped'
            WHEN s < 0.997 THEN 'cancelled'
            ELSE 'pending' END
FROM (SELECT random() AS s FROM generate_series(1, 1000000)) AS draw;

-- One to four lines an order, two and a half on average, each a different product.
INSERT INTO order_lines (order_id, product_id, quantity, unit_price)
SELECT o.id, p.id, 1 + (o.id + k) % 3, p.price
FROM orders AS o
CROSS JOIN generate_series(1, 1 + o.id % 4) AS k
JOIN products AS p ON p.id = 1 + (o.id * 37 + k * 729) % 1000;

-- The two indexes lesson 9 builds its argument on. Nothing on customer_id yet.
CREATE INDEX ON orders (status);
CREATE INDEX ON orders (placed_at);

VACUUM ANALYZE;
```

Three things differ from lesson 1's tables, and each is on purpose. `orders` has **`placed_at
timestamptz`** where the small shop had `ordered_on date`, because at this size a moment matters
and a day does not. There is **no index on `orders.customer_id`** — lesson 10 adds it and measures
what it buys. And `status` has four values, one of them rare — `pending`, about three orders in a
thousand — because lesson 10 needs a value an index is worth using for and one it is not.

## Loading it

Save it as `shop-large.sql` and load it into an empty `shop`. That replaces the small one, which
lesson 12 brings back:

```
ana@vm:~$ dropdb shop
ana@vm:~$ createdb shop
ana@vm:~$ psql shop -f shop-large.sql
 setseed 
---------
 
(1 row)

CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 100000
INSERT 0 1000
INSERT 0 1000000
INSERT 0 2500000
CREATE INDEX
CREATE INDEX
VACUUM
```

The `setseed` line answers with an empty row, which is it agreeing. The rest is a minute or two of
waiting — the last `INSERT` writes two and a half million rows and `VACUUM ANALYZE` reads them all
back — and then this is what you have:

```
ana@vm:~$ psql shop -c "SELECT status, count(*) FROM orders GROUP BY status ORDER BY count(*) DESC"
  status   | count  
-----------+--------
 paid      | 600048
 shipped   | 296744
 cancelled | 100285
 pending   |   2923
(4 rows)

ana@vm:~$ psql shop -c "SELECT count(*) AS order_lines FROM order_lines"
 order_lines 
-------------
     2500000
(1 row)

ana@vm:~$ psql shop -c "SELECT pg_size_pretty(pg_database_size('shop')) AS size"
  size  
--------
 311 MB
(1 row)
```

A million orders in four statuses, two and a half million lines, and **311 MB** on disk, which
is what the virtual machine from lesson 1 grows by.

> **The prompt and the shop.** From here to the end of lesson 11, `shop=#` is this database. Lesson
> 12 goes back to the small one with the three lines from the end of lesson 1.
