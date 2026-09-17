---
title: Five things the mapper does that the code does not say
version: 1
---

A mapper's job is to make the database disappear from the code. It succeeds, and each thing it
hides is a place where the statement the server runs is not the one a reader would guess. The N+1
is the famous one. These are the other five, and each has a lesson behind it.

## 1. It selects every column

`Customer.find(42)` builds a customer object, and the object has every field, so the statement is
`SELECT id, name, email, city, created_at, …` — every column, always. Lesson 10 had the number:
the difference between an index-only scan and one that fetches every row was one column in the
`SELECT` list. A model with a `bio` column of ten kilobytes fetches ten kilobytes per row on a
screen that shows names.

Every ORM has a way to ask for fewer — `only()`, `select()`, `defer()`, a projection into a plain
structure — and the habit is the one lesson 4 started with: name the columns, on the queries that
run often.

## 2. It sends every column on an insert too

Lesson 3 said it and promised the mechanism here. A `DEFAULT` fires when the column is **absent**
from the insert. A mapper building an `INSERT` from an object sends every field the object has,
and a field the code never set is not absent — it is `NULL`:

```
shop=# CREATE TABLE notes (id integer PRIMARY KEY, body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE

shop=# INSERT INTO notes (id, body) VALUES (1, 'from the database');
INSERT 0 1

shop=# INSERT INTO notes (id, body, created_at) VALUES (2, 'from the application', NULL);
ERROR:  null value in column "created_at" of relation "notes" violates not-null constraint
DETAIL:  Failing row contains (2, from the application, null).
```

The first insert left `created_at` out and the database filled it. The second named it and sent
`NULL`, which is a value, and a `NOT NULL` column refused it. Without the constraint the row would
be stored with no timestamp, silently, on a table whose definition says it has one.

Some mappers know which fields were set and omit the rest; some send everything; some have a
per-column flag to say *let the database do this one*. Which yours does is a fact about it that
decides whether a database default ever runs — and a default that never runs is a rule that looks
enforced and is not. The `notes` table above, with a row from each side:

```
shop=# INSERT INTO notes (id, body, created_at) VALUES (2, 'from the application', '2020-01-01');
INSERT 0 1

shop=# SELECT id, body, created_at FROM notes ORDER BY id;
 id |         body         |          created_at           
----+----------------------+-------------------------------
  1 | from the database    | 2026-09-17 23:31:57.290649+00
  2 | from the application | 2020-01-01 00:00:00+00
(2 rows)
```

## 3. It loads in whatever order the table is in

`Customer.all()` with no ordering emits `SELECT … FROM customers` with no `ORDER BY`, and lesson 4
said what that means: the order the engine found convenient, which changes after an update, a
vacuum or a different plan. A list on a screen that is stable for months and then shuffles after a
deploy is this, and the deploy did nothing but change the plan.

Some ORMs add an `ORDER BY` primary key when paginating, because a `LIMIT` with no order is a
different random sample per page. Some do not, and the page that shows a row twice and skips
another is the symptom. Say the order.

## 4. It keeps a transaction open longer than you meant

A data-mapper session is a **unit of work**: it collects the changes made to objects and writes
them at the end, in one transaction. That is a good design and it has a consequence lesson 8
described: the transaction is open from the first read to the commit, holding what a transaction
holds.

The usual shape of the damage is a request handler that loads an order, calls a payment provider
over the network, waits two seconds, and then saves. For those two seconds the transaction is
open, its locks are held, and `VACUUM` cannot reclaim anything newer than it. One handler is
nothing; a thousand a minute is a database that is slowly filling with row versions nobody can
clean.

Two rules. **Do the network call outside the transaction**, and open it afterwards for the write.
And know your framework's default, because it decides whether a slow handler is holding a lock:
Django opens a transaction per request only if you ask it to (`ATOMIC_REQUESTS`), Rails does not
wrap a request at all, and SQLAlchemy's session begins one on first use.

## 5. It caches an object and shows you the stale one

A session remembers the objects it has loaded — the identity map — so that fetching customer 42
twice returns the same object, and a change made through one reference is visible through the
other. Useful, and it means the second fetch may not run a statement at all: the session answers
from memory, with the row as it was when first loaded, whatever the database says now.

That is lesson 8's isolation level, reimplemented one layer up and without the vocabulary. Within
one request it is what you want; across a long-lived session — a background worker that holds one
session for an hour — it is a worker reading data from an hour ago and believing it is current.
Short sessions, one per unit of work, is the rule, and it is the same rule as the transaction one
for the same reason.

## What they have in common

Each of the five is the mapper doing exactly what it documents, and each is visible in one place:
the statement the server received. Every column, `NULL` where a default was expected, no `ORDER
BY`, a `BEGIN` with no `COMMIT` for two seconds, a fetch that never arrived. The log shows all
five, which is why the second section said to leave it on.
