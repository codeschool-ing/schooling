---
title: The shop's database
version: 1
---

PostgreSQL is running and knows nobody yet. Three commands make it yours: a role with your login
name, a database called `shop`, and four settings.

```
ana@lab:~/wh$ sudo -u postgres createuser --superuser $USER
ana@lab:~/wh$ createdb --locale=C.UTF-8 --template=template0 shop
ana@lab:~/wh$ psql -c "ALTER SYSTEM SET timezone = 'America/Sao_Paulo'" -c "ALTER SYSTEM SET shared_buffers = '512MB'" -c "ALTER SYSTEM SET max_parallel_workers_per_gather = 0" -c "ALTER SYSTEM SET jit = off"
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
```

Ubuntu's PostgreSQL trusts the operating system to say who you are, so a role named after your login
needs no password. `--superuser` lets that role change the server's settings, which the third command
does. `--locale=C.UTF-8` makes text sort by the bytes, the same on every machine, so a list ordered
by name comes out in the order the transcripts show.

The four settings make your server behave like the one the course was recorded on. `timezone` prints
times in São Paulo's offset. `shared_buffers` gives PostgreSQL 512 MB of memory to keep pages in, so
the shop's busiest tables fit. The last two turn off parallel workers and just-in-time compilation:
lesson 1 reads a query plan one process wide, and lesson 7 times one, and both read more plainly
without them. **The memory setting only takes effect when the server restarts**, so:

```
ana@lab:~/wh$ sudo pg_ctlcluster 16 main restart
ana@lab:~/wh$ psql -c 'SHOW shared_buffers'
 shared_buffers 
----------------
 512MB
(1 row)
```

## The schema

This is the shop's whole database: fifteen tables, the keys between them, and the indexes the tills
and the website need. Save it as `~/wh/oltp.sql`.

```sql
-- The operational database of Ponto Final: what the tills and the website
-- write to, one transaction at a time. Third normal form, keys enforced, and
-- the CURRENT state of everything: a customer's city is where they live now,
-- a book's price is what it costs today.

CREATE TABLE shops (
    shop_id    integer PRIMARY KEY,
    name       text NOT NULL,
    city       text,
    state      char(2),
    channel    text NOT NULL CHECK (channel IN ('store', 'online')),
    opened_on  date NOT NULL
);

CREATE TABLE categories (
    category_id integer PRIMARY KEY,
    name        text NOT NULL,
    parent_id   integer REFERENCES categories
);

CREATE TABLE publishers (
    publisher_id integer PRIMARY KEY,
    name         text NOT NULL
);

CREATE TABLE authors (
    author_id integer PRIMARY KEY,
    name      text NOT NULL,
    country   char(2) NOT NULL
);

CREATE TABLE books (
    book_id          integer PRIMARY KEY,
    isbn             char(13) NOT NULL UNIQUE,
    title            text NOT NULL,
    category_id      integer NOT NULL REFERENCES categories,
    publisher_id     integer NOT NULL REFERENCES publishers,
    format           text NOT NULL CHECK (format IN ('paperback', 'hardcover', 'ebook')),
    list_price_cents integer NOT NULL CHECK (list_price_cents > 0),
    published_on     date NOT NULL
);

CREATE TABLE book_authors (
    book_id   integer NOT NULL REFERENCES books,
    author_id integer NOT NULL REFERENCES authors,
    position  smallint NOT NULL,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    email       text NOT NULL UNIQUE,
    name        text NOT NULL,
    city        text NOT NULL,
    state       char(2) NOT NULL,
    tier        text NOT NULL CHECK (tier IN ('reader', 'regular', 'patron')),
    created_at  timestamptz NOT NULL,
    updated_at  timestamptz NOT NULL
);

-- Written by the application beside every UPDATE of a customer, because the
-- row itself only remembers the latest value.
CREATE TABLE customer_changes (
    change_id   bigint PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers,
    changed_at  timestamptz NOT NULL,
    field       text NOT NULL,
    old_value   text NOT NULL,
    new_value   text NOT NULL
);

CREATE TABLE promotions (
    promotion_id integer PRIMARY KEY,
    code         text NOT NULL UNIQUE,
    name         text NOT NULL,
    percent_off  integer NOT NULL,
    starts_on    date NOT NULL,
    ends_on      date NOT NULL,
    category     text
);

CREATE TABLE orders (
    order_id       bigint PRIMARY KEY,
    shop_id        integer NOT NULL REFERENCES shops,
    customer_id    integer REFERENCES customers,
    ordered_at     timestamptz NOT NULL,
    status         text NOT NULL,
    shipping_cents integer NOT NULL DEFAULT 0,
    paid_at        timestamptz,
    shipped_at     timestamptz,
    delivered_at   timestamptz
);

CREATE TABLE order_lines (
    order_id         bigint NOT NULL REFERENCES orders,
    line_no          smallint NOT NULL,
    book_id          integer NOT NULL REFERENCES books,
    quantity         smallint NOT NULL CHECK (quantity > 0),
    unit_price_cents integer NOT NULL,
    discount_cents   integer NOT NULL DEFAULT 0,
    promotion_id     integer REFERENCES promotions,
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE payments (
    payment_id   bigint PRIMARY KEY,
    order_id     bigint NOT NULL REFERENCES orders,
    method       text NOT NULL,
    installments smallint NOT NULL,
    amount_cents integer NOT NULL
);

-- The count somebody makes at the end of every month, shelf by shelf.
CREATE TABLE stock_counts (
    count_date date NOT NULL,
    shop_id    integer NOT NULL REFERENCES shops,
    book_id    integer NOT NULL REFERENCES books,
    on_hand    integer NOT NULL,
    PRIMARY KEY (count_date, shop_id, book_id)
);

CREATE TABLE events (
    event_id  integer PRIMARY KEY,
    shop_id   integer NOT NULL REFERENCES shops,
    author_id integer NOT NULL REFERENCES authors,
    held_on   date NOT NULL
);

CREATE TABLE event_attendance (
    event_id    integer NOT NULL REFERENCES events,
    customer_id integer NOT NULL REFERENCES customers,
    PRIMARY KEY (event_id, customer_id)
);

CREATE INDEX ON orders (customer_id);
CREATE INDEX ON orders (ordered_at);
CREATE INDEX ON order_lines (book_id);
CREATE INDEX ON payments (order_id);
CREATE INDEX ON customer_changes (customer_id);
```

It is the shape `sql-databases` builds, and the rest of the course argues with it. Two of its tables
are worth noticing now. `customers` holds where each customer lives *now*, and `books` holds what a
book costs *today*; the history of both survives only because the application writes
`customer_changes` beside every update, and because an order line keeps the price it was sold at.
Section 11 comes back to both.

```
ana@lab:~/wh$ psql -q -f oltp.sql
ana@lab:~/wh$ psql -c '\dt'
             List of relations
 Schema |       Name       | Type  | Owner 
--------+------------------+-------+-------
 public | authors          | table | ana
 public | book_authors     | table | ana
 public | books            | table | ana
 public | categories       | table | ana
 public | customer_changes | table | ana
 public | customers        | table | ana
 public | event_attendance | table | ana
 public | events           | table | ana
 public | order_lines      | table | ana
 public | orders           | table | ana
 public | payments         | table | ana
 public | promotions       | table | ana
 public | publishers       | table | ana
 public | shops            | table | ana
 public | stock_counts     | table | ana
(15 rows)
```

Fifteen tables, all empty. The next section fills them.
