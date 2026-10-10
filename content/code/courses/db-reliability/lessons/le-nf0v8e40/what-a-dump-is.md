---
title: A dump is a program that rebuilds the data
version: 1
---

The commonest picture of a backup is a copy of files: something that reads the database's disk and
writes the same bytes somewhere else. **`pg_dump` is not that.** It connects to the server as an
ordinary client, asks questions, and writes down the answers as instructions for building the
database again. That difference decides what it is good for and where it stops, and this lesson
is about both.

## What it writes

Before looking, give the shop what every real database has and lesson 1 left out: an owner that is
not you, and an application role with only the rights it needs.

```
shop=# CREATE ROLE shop_owner NOLOGIN;
CREATE ROLE

shop=# CREATE ROLE shop_app LOGIN PASSWORD 'app-secret-1';
CREATE ROLE

shop=# ALTER TABLE customers OWNER TO shop_owner;
ALTER TABLE

shop=# ALTER TABLE orders OWNER TO shop_owner;
ALTER TABLE

shop=# GRANT SELECT, INSERT ON orders, customers TO shop_app;
GRANT
```

Now ask `pg_dump` for its default output, plain SQL, and keep only the lines that start a
statement:

```
ana@vm:~$ pg_dump shop | grep -E '^(CREATE|ALTER|GRANT|COPY)'
CREATE TABLE public.customers (
ALTER TABLE public.customers OWNER TO shop_owner;
CREATE TABLE public.orders (
ALTER TABLE public.orders OWNER TO shop_owner;
ALTER TABLE public.orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
COPY public.customers (id, name, city) FROM stdin;
COPY public.orders (id, customer_id, total_cents, placed_at) FROM stdin;
ALTER TABLE ONLY public.customers
ALTER TABLE ONLY public.orders
CREATE INDEX orders_customer ON public.orders USING btree (customer_id);
ALTER TABLE ONLY public.orders
GRANT SELECT,INSERT ON TABLE public.customers TO shop_app;
GRANT SELECT,INSERT ON TABLE public.orders TO shop_app;
```

That is the whole shape of a logical dump. **Create the tables, load the rows, then build the
indexes and constraints, then grant.** The rows travel as `COPY … FROM stdin`, the fastest way
PostgreSQL has to load data, followed by the rows themselves as text. Every `ALTER TABLE ONLY` you
see after the data is a primary or foreign key being added once the rows are in, because checking
fifty thousand rows against a constraint in one pass is much cheaper than checking each row as it
arrives.

Three consequences follow from "a program that rebuilds", and they are the rest of this lesson:

- **It is independent of the server's version and machine.** A dump taken from PostgreSQL 16 on an
  Intel laptop restores into PostgreSQL 17 on an ARM server, because it is SQL. That is why upgrades
  and migrations use it, and why lesson 20 of the administration course did.
- **It describes one database.** Who may log in, and with what password, is not inside any one
  database; the `ALTER … OWNER TO shop_owner` lines name a role the dump does not create. The
  section after next restores into a clean server and watches that fail.
- **Restoring it means doing all the work again.** Every row is inserted, every index built, every
  constraint checked. The last section times that against a database with sixty times the
  shop's orders.

## One moment, even while the database changes

A dump of a busy database is taken while other sessions keep writing. `pg_dump` opens one
transaction and reads everything through **one snapshot**: the state of the whole database at the
instant the dump began. A row inserted a second later is not in it, and neither half of a
transfer that committed during the dump is in it alone. Every table in the file agrees with every
other table about what time it is.

What the snapshot costs is a lock. `pg_dump` holds a light lock on every table it is dumping until
it finishes, which allows reads and writes and refuses schema changes. An `ALTER TABLE` started
during a long dump waits for it, and **every query that arrives after that `ALTER TABLE` waits
behind it**. A nightly dump that takes forty minutes and a migration scheduled for the same hour
make a forty-minute outage that neither job reports as an error.
