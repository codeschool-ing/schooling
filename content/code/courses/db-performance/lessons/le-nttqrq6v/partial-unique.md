---
title: One open cart per customer
version: 1
---

A `UNIQUE` constraint says a value may appear once in a whole table. Business rules are rarely that
broad. They say **one of something at a time**: one open cart per customer, one active
subscription per account, one primary address per person, one unpaid invoice per order. The other
carts, subscriptions and invoices, the closed and finished ones, may repeat as often as they like.
A partial **unique** index says exactly that: unique, but only among the rows its `WHERE` admits.

## A table to try it on

`market` has no carts, so make a small table for them. Write this file as `carts.sql`; the copy
button takes the SQL without the notes:

```schooling-example
{
  "language": "sql",
  "file": "carts.sql",
  "parts": [
    {
      "code": "-- carts.sql: shopping carts, at most one open per customer.\n"
    },
    {
      "code": "CREATE TABLE carts (\n    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,\n    customer_id integer     NOT NULL REFERENCES customers (id),\n    status      text        NOT NULL DEFAULT 'open'\n                CHECK (status IN ('open', 'ordered', 'abandoned')),\n    created_at  timestamptz NOT NULL DEFAULT now()\n);\n\n",
      "note": "**A cart lives through three states.** It is `open` while the customer adds things to it, and becomes `ordered` or `abandoned` when it ends. Old carts are kept: they are the history of what people almost bought."
    },
    {
      "code": "CREATE UNIQUE INDEX carts_one_open_idx ON carts (customer_id)\n    WHERE status = 'open';\n",
      "note": "**The rule, as an index.** Unique on `customer_id`, but only among the rows where `status = 'open'`. A customer may have any number of ordered and abandoned carts, and one open one. A plain `UNIQUE (customer_id)` would allow one cart per customer, ever."
    }
  ]
}
```

Run it into `market`:

```
ana@vm:~$ psql market -f carts.sql
CREATE TABLE
Time: 14.756 ms
CREATE INDEX
Time: 1.757 ms
```

The rule lives in the index, `carts_one_open_idx`, and nowhere else. Nothing in the table's
definition says "one open cart"; drop the index and the rule is gone.

## Trying to break it

```
market=# INSERT INTO carts (customer_id) VALUES (42);
INSERT 0 1
Time: 4.751 ms

market=# INSERT INTO carts (customer_id) VALUES (42);
ERROR:  duplicate key value violates unique constraint "carts_one_open_idx"
DETAIL:  Key (customer_id)=(42) already exists.
Time: 0.817 ms

market=# INSERT INTO carts (customer_id) VALUES (42) ON CONFLICT (customer_id) WHERE status = 'open' DO NOTHING;
INSERT 0 0
Time: 0.614 ms

market=# UPDATE carts SET status = 'ordered' WHERE customer_id = 42 AND status = 'open';
UPDATE 1
Time: 1.642 ms

market=# INSERT INTO carts (customer_id) VALUES (42);
INSERT 0 1
Time: 1.533 ms

market=# SELECT id, customer_id, status FROM carts ORDER BY id;
 id | customer_id | status  
----+-------------+---------
  1 |          42 | ordered
  4 |          42 | open
(2 rows)

Time: 1.058 ms
```

Read it from the top.

- **The first insert** makes customer 42's open cart.
- **The second** tries to make another and is refused, with the index named in the error and the
  value it collided on. The database enforced the business rule, and no application code was asked.
- **`ON CONFLICT … DO NOTHING`** is the polite form for an application: "make an open cart unless
  there is one". `INSERT 0 0` is the answer "there was one". The `WHERE status = 'open'` after
  `ON CONFLICT (customer_id)` is not decoration. PostgreSQL has to find a unique index that matches
  the conflict target, and only a target that repeats the index's own predicate matches a partial
  one.
- **The update** closes the cart, and from that moment the row is no longer in the index.
- **The last insert** opens a new cart for the same customer, and it goes in.

The final `SELECT` shows two carts for customer 42, one ordered and one open, which is the state
the rule allows. The ids are 1 and 4, not 1 and 2: the refused insert and the skipped one had each
already drawn a number from the identity sequence, and a sequence never gives a number back. A gap in an
identity column can be an insert that never happened, as well as a row that was deleted.

## Why not check it in the application

The alternative everybody writes first is a `SELECT` for an open cart, and an `INSERT` if there is
none. It works in every test, because a test sends one request at a time. In production, two
clicks on "add to cart" a few milliseconds apart run the same `SELECT` at the same moment, both
find nothing, and both insert. Now the customer has two open carts and the application's next
query, which expects one, picks either. Lesson 14 is about races of exactly this shape, and the
general cure there is a stricter isolation level with retries. For a rule of this shape the cure is
cheaper: the unique index checks every insert against every other, committed or not, and the
second of two simultaneous inserts waits for the first and then fails.

## The size

The index holds one entry per open cart, so its size follows the number of customers shopping
right now, not the number of carts ever made. That is the property of section 02 again, applied to
a rule instead of a query: the slice of the table that matters is small, and the index is that
slice.
