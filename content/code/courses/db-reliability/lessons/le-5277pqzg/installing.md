---
title: Installing PostgreSQL, and the database you will lose
version: 1
---

From the prompt of your Ubuntu machine, two commands install the server, the `psql` client and the
tools around them:

```sh
sudo apt update
sudo apt install -y postgresql
```

`apt` prints a screen of progress, and its last lines are about creating a **cluster**: Ubuntu's
word, and PostgreSQL's, for one running server and the directory its data lives in. Ask what you
got:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Version 16, one cluster called `main`, on port 5432, **`online`**. The two right-hand columns are
the ones this course comes back to most: the **data directory**, which is the database as files on
disk, and the **log**, which is the first place to look when something has gone wrong. When lesson
3 adds a second server, it is a second line in this table.

## You, as the database knows you

PostgreSQL keeps its own list of who may connect, separate from the users of the computer. The
installer put one name on it, `postgres`, and you are not it:

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

A **role** is a database user. Make one with your own name, as `postgres`, who is allowed to:

```
ana@vm:~$ sudo -u postgres createuser --superuser $USER
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

`createuser` printed nothing, which is how it says it worked. `--superuser` lets your role do
anything on this server, which is right for a machine that is yours alone and wrong anywhere else.
The second refusal is progress: you got in, and there was no database called `ana` to get into.
This course uses one called `shop`:

```
ana@vm:~$ createdb shop
```

## The shop

Every lesson works on the same small database: a thousand customers and fifty thousand orders. It
is generated rather than downloaded, by a script that produces the same rows every time it runs,
and that property matters more than it looks. When lesson 6 restores the shop to a moment before a
mistake, you will check the result against numbers printed here, and they only mean something if
your copy and this one were built the same way.

Save this as `shop.sql` in your home directory. The copy button above the code takes the whole
script without the notes.

```schooling-example
{"language": "sql", "file": "shop.sql", "parts": [{"code": "-- shop.sql: the course's database, built the same way every time\nDROP TABLE IF EXISTS orders, customers;\n", "note": "Every run starts from nothing. Dropping both tables first means the script can be run again, which lesson 2 does."}, {"code": "CREATE TABLE customers (\n  id   bigint PRIMARY KEY,\n  name text NOT NULL,\n  city text NOT NULL\n);\n\nCREATE TABLE orders (\n  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,\n  customer_id bigint NOT NULL REFERENCES customers,\n  total_cents integer NOT NULL CHECK (total_cents > 0),\n  placed_at   timestamptz NOT NULL\n);\n", "note": "Two tables joined by a foreign key, so that a restore which brings back one table and not the other fails loudly."}, {"code": "INSERT INTO customers\nSELECT i, 'customer ' || i,\n       (ARRAY['Recife', 'Porto Alegre', 'Belém', 'Curitiba'])[1 + i % 4]\nFROM generate_series(1, 1000) AS i;\n", "note": "`generate_series` produces the numbers 1 to 1000, and each becomes a customer. The city is picked by the remainder, so a quarter of them live in each."}, {"code": "INSERT INTO orders (customer_id, total_cents, placed_at)\nSELECT 1 + (i * 7919) % 1000,\n       500 + (i::bigint * 104729) % 20000,\n       timestamptz '2026-01-01 09:00-03' + i * interval '7 minutes'\nFROM generate_series(1, 50000) AS i;\n", "note": "No random numbers anywhere. Multiplying by a prime and taking the remainder scatters the customers and the totals, and gives the same answer on every machine. One order every seven minutes from the first of January covers eight months."}, {"code": "CREATE INDEX orders_customer ON orders (customer_id);", "note": "An index, because a restore has to rebuild them and that takes time worth measuring."}]}
```

Run it, and look at what you made:

```
ana@vm:~$ psql shop -f shop.sql
psql:shop.sql:2: NOTICE:  table "orders" does not exist, skipping
psql:shop.sql:2: NOTICE:  table "customers" does not exist, skipping
DROP TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1000
INSERT 0 50000
CREATE INDEX
```

The two `NOTICE` lines are the `DROP TABLE IF EXISTS` finding nothing to drop the first time,
which is harmless. Then:

```
shop=# SELECT count(*) AS customers FROM customers;
 customers 
-----------
      1000
(1 row)

shop=# SELECT count(*) AS orders, min(placed_at), max(placed_at) FROM orders;
 orders |          min           |          max           
--------+------------------------+------------------------
  50000 | 2026-01-01 09:07:00-03 | 2026-09-01 10:20:00-03
(1 row)
```

**Fifty thousand orders, from 1 January to 1 September 2026.** Keep those two numbers in mind; the
rest of this lesson is about getting them back.
