---
title: What the four actually are
version: 1
---

Eleven lessons have gone by with hardly a product name in them. That was not an omission. The
relational model, `SELECT`, the joins, `GROUP BY`, transactions, indexes and the plan are one
subject, and the engine that runs them is a detail for almost all of it.

This lesson is about the rest — the places where the engine stops being a detail. There are four
of them here, and the first thing to get right is what each one **is**, because two of them are
not the kind of thing the other two are.

## PostgreSQL

A database server, developed since 1996 by a distributed group of contributors with no single
company behind it, under a permissive licence of its own. It is the strictest of the four about
what it will accept, the widest in what it can store, and the one with an extension mechanism that
other projects build on — PostGIS for geography, TimescaleDB for time series, `pgvector` for
embeddings are all Postgres with something loaded into it.

The name is said *post-gres-cue-ell*, and the project answers to `postgres` in every command you
type, which is what the rest of this lesson uses.

## MySQL

A database server, released in 1995, bought by Sun in 2008 and with Sun by Oracle in 2010. It is
dual-licensed: GPL for the community edition, and a commercial licence for the rest. It is the
engine behind an enormous amount of the web — WordPress, most shared hosting, a great deal of
what was built between 2000 and 2015 — and that installed base is the main reason you will meet
it.

## MariaDB

The fork of MySQL that the original authors started in 2009, when Oracle acquired Sun. It is GPL,
with no commercial edition of the engine, and for several years it was a drop-in replacement: the
same protocol, the same client, the same SQL. Fifteen years of separate development have moved
the two apart, and the section on the fork is about how far.

## SQLite

**Not a server.** It is a C library that your program links against, and the database is one file
on disk. There is no process to start, no port to connect to, no user to create. It is in the
public domain, it is the most widely deployed database in the world by an enormous margin — every
Android phone, every iPhone, every browser, most desktop applications — and it is the one whose
place in the list is most often misunderstood.

## The shape of the comparison

Three of the four are servers you talk to over a socket; one is a library inside your process. Two
of the servers share an ancestor and most of a dialect; the third does not.

| | PostgreSQL | MySQL | MariaDB | SQLite |
|---|---|---|---|---|
| what it is | server | server | server | library |
| first released | 1996 | 1995 | 2009 | 2000 |
| licence | PostgreSQL licence | GPL + commercial | GPL | public domain |
| stewarded by | no single owner | Oracle | MariaDB Foundation and MariaDB plc | no single owner |
| default storage engine | its own | InnoDB | InnoDB | its own |

Everything from here is what follows from that table. The versions this lesson was written
against are the ones in the transcripts: PostgreSQL 16.15, MySQL 8.0.46, MariaDB 10.11.14 and
SQLite 3.45.1, each running the shop from lesson 1 — the small one, with five customers, not the
million orders of lessons 9 to 11.

## Following along

**You do not need the other three to follow this lesson.** Every comparison in it is printed from
each engine, and the output is the point. Your PostgreSQL needs the small shop back — lesson 1's
three lines, `dropdb shop`, `createdb shop`, `psql shop -f shop.sql` — and that is all.

If you want to run the others, two of them are one command each in your Ubuntu machine, and the
third needs a machine of its own:

```sh
sudo apt install -y sqlite3        # SQLite 3.45
sudo apt install -y mysql-server   # MySQL 8.0
```

MariaDB is `sudo apt install -y mariadb-server`, and it **replaces** MySQL rather than sitting
beside it: Ubuntu's packages for the two cannot be installed together. Install it in a second virtual machine — a clone of the first, from lesson 1, is the
quickest — or after removing MySQL.

The shop then has to be written in each engine's dialect, which is half of what this lesson is
about. For SQLite:

```sql
-- shop-sqlite.sql: lesson 1's shop, for SQLite.
-- Load it with:  sqlite3 shop.db < shop-sqlite.sql

CREATE TABLE customers (
    id     INTEGER PRIMARY KEY,
    name   TEXT    NOT NULL,
    email  TEXT    NOT NULL UNIQUE,
    city   TEXT
);

CREATE TABLE products (
    id     INTEGER PRIMARY KEY,
    sku    TEXT          NOT NULL UNIQUE,
    name   TEXT          NOT NULL,
    price  NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    ordered_on  TEXT    NOT NULL DEFAULT (date('now')),
    total       NUMERIC(10,2) NOT NULL CHECK (total >= 0),
    status      TEXT    NOT NULL DEFAULT 'placed'
                        CHECK (status IN ('placed', 'shipped', 'cancelled'))
);

CREATE TABLE order_lines (
    order_id   INTEGER NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO customers (name, email, city) VALUES
    ('Ana Ribeiro',  'ana@example.com',   'Recife'),
    ('Bruno Costa',  'bruno@example.com', 'Sao Paulo'),
    ('Carla Mendes', 'carla@example.com', 'Recife'),
    ('Diego Alves',  'diego@example.com', 'Curitiba'),
    ('Elisa Fontes', 'elisa@example.com', NULL);

INSERT INTO products (sku, name, price) VALUES
    ('KB-101', 'Mechanical keyboard',  349.90),
    ('MS-204', 'Wireless mouse',       189.00),
    ('MN-330', '27-inch monitor',     1499.00),
    ('CB-012', 'USB-C cable',           39.90);

INSERT INTO orders (customer_id, ordered_on, total) VALUES
    (1, '2026-03-02', 1499.00),
    (4, '2026-03-03', 2998.00),
    (1, '2026-03-04',  268.80),
    (1, '2026-03-09',  349.90);

INSERT INTO order_lines (order_id, product_id, quantity, unit_price) VALUES
    (1, 3, 1, 1499.00),
    (2, 3, 2, 1499.00),
    (3, 4, 2,   39.90),
    (3, 2, 1,  189.00),
    (4, 1, 1,  349.90);
```

And for MySQL and MariaDB, which share it:

```sql
-- shop-mysql.sql: lesson 1's shop, for MySQL and MariaDB.
-- Load it with:  sudo mysql -e 'CREATE DATABASE shop' && sudo mysql shop < shop-mysql.sql

CREATE TABLE customers (
    id     int          AUTO_INCREMENT PRIMARY KEY,
    name   varchar(120) NOT NULL,
    email  varchar(120) NOT NULL UNIQUE,
    city   varchar(120)
);

CREATE TABLE products (
    id     int           AUTO_INCREMENT PRIMARY KEY,
    sku    varchar(20)   NOT NULL UNIQUE,
    name   varchar(120)  NOT NULL,
    price  decimal(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          int           AUTO_INCREMENT PRIMARY KEY,
    customer_id int           NOT NULL,
    ordered_on  date          NOT NULL DEFAULT (curdate()),
    total       decimal(10,2) NOT NULL CHECK (total >= 0),
    status      varchar(10)   NOT NULL DEFAULT 'placed'
                              CHECK (status IN ('placed', 'shipped', 'cancelled')),
    FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
);

CREATE TABLE order_lines (
    order_id   int           NOT NULL,
    product_id int           NOT NULL,
    quantity   int           NOT NULL CHECK (quantity > 0),
    unit_price decimal(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders   (id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);

INSERT INTO customers (name, email, city) VALUES
    ('Ana Ribeiro',  'ana@example.com',   'Recife'),
    ('Bruno Costa',  'bruno@example.com', 'Sao Paulo'),
    ('Carla Mendes', 'carla@example.com', 'Recife'),
    ('Diego Alves',  'diego@example.com', 'Curitiba'),
    ('Elisa Fontes', 'elisa@example.com', NULL);

INSERT INTO products (sku, name, price) VALUES
    ('KB-101', 'Mechanical keyboard',  349.90),
    ('MS-204', 'Wireless mouse',       189.00),
    ('MN-330', '27-inch monitor',     1499.00),
    ('CB-012', 'USB-C cable',           39.90);

INSERT INTO orders (customer_id, ordered_on, total) VALUES
    (1, '2026-03-02', 1499.00),
    (4, '2026-03-03', 2998.00),
    (1, '2026-03-04',  268.80),
    (1, '2026-03-09',  349.90);

INSERT INTO order_lines (order_id, product_id, quantity, unit_price) VALUES
    (1, 3, 1, 1499.00),
    (2, 3, 2, 1499.00),
    (3, 4, 2,   39.90),
    (3, 2, 1,  189.00),
    (4, 1, 1,  349.90);
```

The rows are lesson 1's `INSERT`s, unchanged — they are the portable part. The `sqlite3`
transcripts in this lesson are taken with `sqlite3 -column -header shop.db`, which draws the
headings, and the `mysql` ones with `sudo mysql -t shop`, which draws the boxes.

There is a fifth engine you will meet in a corporate job, and it is different enough — in what it
costs, in how it is bought, and in what it does to the shape of a system — that it gets lesson 13
to itself.
