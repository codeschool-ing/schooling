---
title: Installing PostgreSQL and the course's database
version: 1
---

From the prompt of your Ubuntu machine, two commands install the server and the `psql` client:

```sh
sudo apt update
sudo apt install -y postgresql
```

`apt` prints a minute of progress and ends by creating a **cluster**, PostgreSQL's word for one
running server and the directory its data lives in. Ask what you got:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

## A role and a database

The server keeps its own list of who may connect, and the only name on it is `postgres`. Give
yourself a role with your own name, then a database for this course:

```
ana@vm:~$ sudo -u postgres createuser --superuser $USER
ana@vm:~$ createdb market
```

`createuser` and `createdb` print nothing when they work. `--superuser` lets your role change
the server's settings, which this course does in almost every lesson — right on a machine that
is yours alone, and wrong on any server somebody else depends on.

## The database, made up from a fixed seed

A performance course needs a database that is **slow on purpose**. A table of a hundred rows
answers every query in a fraction of a millisecond whatever you do to it, so there is nothing to
measure, nothing to fix and nothing to learn. This file makes a marketplace big enough to have
plans worth reading: a thousand sellers, two hundred thousand customers, fifty thousand products,
two million orders and five million events.

Nobody types two million orders. The file makes them up with `random()`, from a **fixed seed**,
so your database and the one in the transcripts hold the same rows. Copy it whole into a file
called `market.sql`:

```sql
-- market.sql: the database of db-performance, made up from a fixed seed.
-- A marketplace: sellers list products, customers place orders, and the
-- site logs what everybody clicks. Two runs make the same rows.
-- Load it into an empty database:  psql market -f market.sql
SELECT setseed(0.17);

CREATE TABLE sellers (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text NOT NULL
);

CREATE TABLE customers (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      text NOT NULL UNIQUE,
    name       text NOT NULL,
    city       text NOT NULL,
    state      text NOT NULL,
    created_at timestamptz NOT NULL
);

CREATE TABLE products (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id   integer NOT NULL REFERENCES sellers (id),
    title       text    NOT NULL,
    tags        text[]  NOT NULL,
    price_cents integer NOT NULL CHECK (price_cents > 0)
);

CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer     NOT NULL REFERENCES customers (id),
    seller_id   integer     NOT NULL REFERENCES sellers (id),
    placed_at   timestamptz NOT NULL,
    status      text        NOT NULL,
    total_cents integer     NOT NULL
);

CREATE TABLE order_lines (
    order_id    bigint   NOT NULL REFERENCES orders (id),
    line        smallint NOT NULL,
    product_id  integer  NOT NULL REFERENCES products (id),
    quantity    integer  NOT NULL,
    price_cents integer  NOT NULL,
    PRIMARY KEY (order_id, line)
);

CREATE TABLE events (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    at          timestamptz NOT NULL,
    customer_id integer,
    kind        text  NOT NULL,
    payload     jsonb NOT NULL
);

-- 1,000 sellers. Seller 1 is the marketplace's own store, and it is big.
INSERT INTO sellers (name)
SELECT CASE WHEN n = 1 THEN 'Market Own Store' ELSE 'Seller ' || n END
FROM generate_series(1, 1000) AS n;

-- 200,000 customers in twelve cities. A city always has the same state, and
-- more people live in some cities than in others.
INSERT INTO customers (email, name, city, state, created_at)
SELECT 'user' || n || '@example.com',
       (ARRAY['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fabio',
              'Helena', 'Igor', 'Julia', 'Marcos'])[1 + floor(random() * 10)]
       || ' ' ||
       (ARRAY['Alves', 'Costa', 'Lima', 'Mendes', 'Oliveira',
              'Ribeiro', 'Rocha', 'Santos', 'Souza', 'Teixeira'])[1 + floor(random() * 10)],
       (ARRAY['Sao Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Campinas',
              'Curitiba', 'Porto Alegre', 'Salvador', 'Recife',
              'Niteroi', 'Santos', 'Fortaleza', 'Manaus'])[c],
       (ARRAY['SP', 'RJ', 'MG', 'SP', 'PR', 'RS', 'BA', 'PE',
              'RJ', 'SP', 'CE', 'AM'])[c],
       timestamptz '2022-01-01 00:00-03' + random() * interval '1460 days'
FROM (SELECT n, 1 + floor(12 * power(random(), 2))::int AS c
      FROM generate_series(1, 200000) AS n) AS pick;

-- 50,000 products: a title of three words, and two or three tags.
INSERT INTO products (seller_id, title, tags, price_cents)
SELECT CASE WHEN random() < 0.2 THEN 1 ELSE 2 + floor(random() * 999)::int END,
       (ARRAY['Blue', 'Compact', 'Classic', 'Wooden', 'Steel', 'Portable',
              'Organic', 'Smart', 'Vintage', 'Wireless'])[1 + floor(random() * 10)]
       || ' ' ||
       (ARRAY['lamp', 'chair', 'kettle', 'backpack', 'speaker', 'notebook',
              'blender', 'jacket', 'drill', 'mug'])[1 + floor(random() * 10)]
       || ' ' || n,
       ARRAY[(ARRAY['home', 'kitchen', 'office', 'outdoor', 'kids'])[1 + floor(random() * 5)],
             (ARRAY['gift', 'sale', 'new', 'eco', 'premium'])[1 + floor(random() * 5)]]
       || CASE WHEN random() < 0.1 THEN ARRAY['clearance'] ELSE '{}' END,
       100 * (5 + floor(random() * 500)::int) + 90
FROM generate_series(1, 50000) AS n;

-- 2,000,000 orders over the three years 2023 to 2025, more each year, written
-- in the order they were placed. A quarter of them are seller 1's. Most were
-- delivered long ago; the last two weeks are still on their way.
INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)
SELECT customer_id, seller_id, placed_at,
       CASE WHEN placed_at >= '2025-12-29' THEN 'pending'
            WHEN placed_at >= '2025-12-17' THEN 'shipped'
            WHEN s < 0.03 THEN 'cancelled'
            ELSE 'delivered' END,
       total_cents
FROM (SELECT 1 + floor(random() * 200000)::int AS customer_id,
             CASE WHEN random() < 0.25 THEN 1 ELSE 2 + floor(random() * 999)::int END AS seller_id,
             timestamptz '2023-01-01 00:00-03' + sqrt(random()) * interval '1095 days' AS placed_at,
             random() AS s,
             500 + floor(random() * 50000)::int AS total_cents
      FROM generate_series(1, 2000000)) AS draw
ORDER BY placed_at;

-- One to four lines an order, two and a half on average.
INSERT INTO order_lines (order_id, line, product_id, quantity, price_cents)
SELECT o.id, k, 1 + (o.id * 7919 + k * 104729) % 50000, 1 + (o.id + k) % 3,
       100 * (5 + (o.id * k) % 500) + 90
FROM orders AS o
CROSS JOIN generate_series(1, 1 + (o.id % 4)::int) AS k;

-- 5,000,000 events over the last ninety days of 2025, in the order they
-- happened. Three in ten are visitors with no account.
INSERT INTO events (at, customer_id, kind, payload)
SELECT at,
       CASE WHEN random() < 0.3 THEN NULL ELSE 1 + floor(random() * 200000)::int END,
       kind,
       jsonb_build_object('product', 1 + floor(random() * 50000)::int,
                          'ms', 20 + floor(random() * 400)::int)
FROM (SELECT timestamptz '2025-10-03 00:00-03' + random() * interval '90 days' AS at,
             (ARRAY['view', 'view', 'view', 'view', 'view', 'view',
                    'search', 'search', 'cart', 'checkout'])[1 + floor(random() * 10)] AS kind
      FROM generate_series(1, 5000000)) AS draw
ORDER BY at;

-- The indexes the application was born with: one for each foreign key that
-- a screen reads by, and the time an order was placed.
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
CREATE INDEX orders_placed_at_idx ON orders (placed_at);
CREATE INDEX order_lines_product_id_idx ON order_lines (product_id);

VACUUM ANALYZE;
```

Some of its choices are mistakes a real database would also have, made here on purpose, because
the lessons that follow need them:

- **Seller 1 is enormous.** A quarter of all orders are the marketplace's own store, and the
  other 999 share the rest. Lesson 7 is about what that does to an estimate.
- **A city always has the same state**, so the two columns say one thing twice. The planner
  assumes they are independent, and lesson 7 shows the price.
- **Orders and events are written in time order**, the way a real application writes them.
  Lesson 8's BRIN index depends on it.
- **There is no index on `orders.seller_id`**, although a seller's screen reads by it all day.
  Lesson 2 finds it from the outside, the way you would find it at work.

## Loading it

```sh
psql market -v ON_ERROR_STOP=1 -f market.sql
```

`ON_ERROR_STOP` makes `psql` stop at the first statement that fails, instead of reporting the
error and carrying on with the next one — which, for a file that creates tables and then fills
them, is the difference between a clear failure and a half-built database. It takes a few
minutes. Each statement reports what it did as it finishes, and the last `INSERT`
writes five million rows. Here is the whole load, timed with the shell's `time`:

```
ana@vm:~$ time psql market -v ON_ERROR_STOP=1 -f market.sql
 setseed 
---------
 
(1 row)

CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1000
INSERT 0 200000
INSERT 0 50000
INSERT 0 2000000
INSERT 0 5000000
INSERT 0 5000000
CREATE INDEX
CREATE INDEX
CREATE INDEX
VACUUM

real	2m18.547s
user	0m0.032s
sys	0m0.004s
```

**Two minutes and 19 seconds on the computer this course was recorded on**, which has four
processors and plenty of memory. A virtual machine with two processors takes longer, and that is
the right time to go and make coffee. `real` is the time on the clock; `user` and `sys` are what
`psql` itself spent, which is almost nothing, because the work happens in the server.

## One line of configuration

Every lesson times queries, so tell `psql` to do it every time it starts. This writes a file
`psql` reads when it opens:

```sh
cat > ~/.psqlrc <<'RC'
\set QUIET on
\timing on
\unset QUIET
RC
```

The middle line is the setting. The two around it stop `psql` announcing it every time.

From now on every statement is followed by a line saying how long it took, measured by `psql`
from the moment it sent the query to the moment the answer arrived.

Then open the database and look at what you have:

```
ana@vm:~$ psql market
market=# SELECT relname AS table, reltuples::bigint AS rows, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC;
    table    |  rows   |  size   
-------------+---------+---------
 events      | 4999827 | 618 MB
 order_lines | 4999992 | 432 MB
 orders      | 2000000 | 234 MB
 customers   |  200000 | 36 MB
 products    |   50000 | 6344 kB
 sellers     |    1000 | 128 kB
(6 rows)

Time: 4.020 ms

market=# SELECT pg_size_pretty(pg_database_size('market')) AS database;
 database 
----------
 1334 MB
(1 row)

Time: 1.903 ms
```

**1334 MB** on disk, most of it events and order lines. That is about ten times the 128 MB
PostgreSQL keeps for itself out of the box, which is the point: some of what you ask for will have
to come from the disk, and the difference is one of the things this course measures.

Two of the row counts are a little off — `4999908` events where the file wrote five million — and
that is not a fault in the load. The column comes from `reltuples`, which is the server's own
**estimate** of how many rows a table has, kept up to date by `VACUUM` and `ANALYZE` from a
sample. It is the number the planner works with, and lesson 6 is about what happens when it is far
wrong rather than a little.

The `Time:` under each answer is the setting from a moment ago at work.
