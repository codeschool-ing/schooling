---
title: The primary key: what makes a row that row
version: 1
---

Rows have no order and no position, so if you want to talk about one row rather than another, the
row itself has to carry something that no other row carries. That something is the **primary
key**.

```sql
CREATE TABLE customers (
    id     integer PRIMARY KEY,
    ...
);
```

`PRIMARY KEY` says two things at once, and it is worth separating them because they fail
differently:

1. **This column is unique.** No two rows may hold the same value. An insert that tries is
   refused.
2. **This column is never empty.** It may not be `NULL`.

Together they mean: given a value, there is exactly one row, or there is none. Never two, never
"probably that one".

## Watch it refuse

```sql
INSERT INTO customers (id, name, email) VALUES (1, 'Ana Lopes', 'ana@example.com');
INSERT INTO customers (id, name, email) VALUES (1, 'Bruno Sá', 'bruno@example.com');
```

```
ERROR:  duplicate key value violates unique constraint "customers_pkey"
DETAIL:  Key (id)=(1) already exists.
```

Read what happened there. The second row was **not** written and then flagged; it was never
written at all. The database refused the statement and the table is exactly as it was.

This is the difference between a rule and a report. A spreadsheet can be *checked* for duplicates
afterwards, which means there is a window — minutes, or months — during which the duplicate exists
and everything reading the sheet gets a wrong answer. A primary key means **the bad state never
existed**. There is no window.

## Natural keys and surrogate keys

Something in your data may already be unique. An email address, a tax number, an ISBN, a country
code. Using one of those as the primary key is called a **natural key**: the identifier comes from
the world.

Inventing a number that means nothing and belongs to nobody is a **surrogate key**: the identifier
comes from the database.

Natural keys are tempting because they save a column and because `WHERE email = ...` reads better
than `WHERE id = 4471`. They are usually still the wrong choice, and here is the argument.

**A natural key has to be unique, and it has to never change.** Almost nothing in the world is
both.

- Email addresses are unique — until somebody changes theirs. Now every row pointing at the old
  address is pointing at nothing, and you are editing the key in every table that referenced it.
- A tax number is unique per country, and your second country has its own numbering.
- An ISBN identifies an edition, not a book, and a book can be reissued.
- Even a passport number is reused after enough decades.

The failure is specific and expensive: **a key that changes has to be changed everywhere it was
copied to**, which is exactly the problem the relational model exists to remove. A surrogate key
cannot change, because it never meant anything in the first place — there is no fact about the
world that could make `4471` wrong.

So the default:

> Give every table a surrogate primary key. Put the natural uniqueness in a `UNIQUE` constraint
> beside it.

```sql
CREATE TABLE customers (
    id     integer PRIMARY KEY,
    email  text    NOT NULL UNIQUE,
    name   text    NOT NULL
);
```

Now `id` identifies the row forever, `email` is still guaranteed unique, and the day Ana changes
her address you update one column in one row and nothing else in the database notices.

## Where the number comes from

Nobody types primary keys by hand. The database generates them:

```sql
CREATE TABLE customers (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email  text    NOT NULL UNIQUE,
    name   text    NOT NULL
);

INSERT INTO customers (name, email) VALUES ('Ana Lopes', 'ana@example.com');
```

`GENERATED ALWAYS AS IDENTITY` is the standard spelling. You will also meet `SERIAL` in older
PostgreSQL, `AUTO_INCREMENT` in MySQL and MariaDB, and `INTEGER PRIMARY KEY` in SQLite, which all
do the same job with different words. Lesson 12 is about those differences; for now, know that the
column fills itself.

**Two things about generated numbers that surprise people.**

They have gaps. A transaction that gets a number and then rolls back does not give the number
back, so `1, 2, 5, 6` is a healthy table and not a sign that rows were deleted. Counting rows by
looking at the highest id is wrong.

And they are guessable. If `/orders/1004` is a valid address in your application, so is
`/orders/1003`, and it belongs to somebody else. That is an authorisation problem and not a key
problem — the fix is checking who is asking, not hiding the number — but it is the reason public
systems often carry a second, random identifier (a `UUID`) for use in URLs, while keeping the
small integer internally.

## Keys made of more than one column

A primary key may be several columns together. This is a **composite key**, and it says that the
*combination* is unique even though neither column is:

```sql
CREATE TABLE seat_bookings (
    flight_id integer NOT NULL,
    seat      text    NOT NULL,
    passenger text    NOT NULL,
    PRIMARY KEY (flight_id, seat)
);
```

Flight 431 appears many times, seat `12A` appears many times, and `(431, '12A')` appears once —
which is exactly the rule an airline needs. Trying to book a taken seat is refused by the
database, without a line of application code, and the refusal is not subject to two people
clicking at the same moment.

Composite keys are the natural shape for the join tables in the many-to-many section later on.
They are less comfortable as the key of an ordinary table, for the same reason natural keys are:
everything that points at the row has to carry both columns.

## The one test

If you remember one thing from this section, make it the question to ask of any candidate key:

> **Could two different things in the real world ever produce the same value? And could the same
> thing ever produce a different one?**

A "yes" to the first means it is not unique. A "yes" to the second means it is not stable. A key
needs "no" to both, and a number that means nothing is the only thing that answers "no" without
argument.
