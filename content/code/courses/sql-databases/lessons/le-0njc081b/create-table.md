---
title: The statement, and the habits that go in it
version: 2
---

Two lessons of design, and now you write it down.

```sql
CREATE TABLE invoices (
    id          integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer       NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    number      text          NOT NULL UNIQUE,
    issued_on   date          NOT NULL DEFAULT current_date,
    total       numeric(12,2) NOT NULL CHECK (total >= 0),
    paid_at     timestamptz,
    CONSTRAINT invoices_paid_after_issue
        CHECK (paid_at IS NULL OR paid_at::date >= issued_on)
);
```

Every part of that has appeared in the last two lessons except the shape of the statement itself,
which is what this section is about. Read it as three kinds of line:

- **column definitions** — a name, a type, and any constraints that apply to that column alone;
- **table constraints** — at the end, for anything that spans more than one column;
- **nothing else.** There is no place in `CREATE TABLE` for a comment about intent, which is why
  the last section of this lesson is about naming.

## `IF NOT EXISTS` and why it is usually wrong

```sql
CREATE TABLE IF NOT EXISTS invoices ( … );
```

It looks defensive and it is dangerous, because **it does not check that the existing table
matches**. If `invoices` is already there with a different shape, this succeeds silently and your
program now runs against a table you did not write.

It has one honest use: a script that is genuinely idempotent and whose table definition is the only
one that has ever existed. In a system with migrations — lesson 11 — each migration runs once and
`IF NOT EXISTS` hides the fact that one ran twice, which is a thing you want to be told.

## Naming, which you will live with longer than the code

There is no universal standard, and there is a common one worth following unless your team already
has another:

| | |
|---|---|
| **`snake_case`**, lower | `issued_on`, not `issuedOn` or `IssuedOn` |
| **table names plural** | `invoices`, because the table holds many |
| **column names singular** | `total`, because the column holds one per row |
| **a foreign key is `<table-singular>_id`** | `customer_id` points at `customers.id` |
| **dates end in `_on`, moments in `_at`** | `issued_on` is a date, `paid_at` is a timestamp |

The case rule is not a preference in PostgreSQL, it is a trap. **Unquoted identifiers are folded
to lower case**, so `CREATE TABLE Invoices` creates a table called `invoices` and everything works
— until somebody writes `CREATE TABLE "Invoices"` with quotes, which creates a *different* table
that can only ever be referred to with quotes. One accidental pair of quotes produces a schema
where half the tables need them and half do not.

The `_on` / `_at` convention earns its keep the first time you read somebody else's schema: you
can tell a date from a timestamp without looking it up, and the difference matters more than
people expect, as the `time` section explains.

## Order the columns for a reader

The database does not care. A person reading `\d invoices` at three in the morning does:

1. the key,
2. the foreign keys — because they say what this row is attached to,
3. the things that identify it to a human — a number, a name, a code,
4. the rest,
5. the timestamps last, because they are on nearly every table and carry the least meaning.

## One table per statement, and the transaction around it

DDL in PostgreSQL is **transactional**, which is not true of every database and is worth knowing:

```sql
BEGIN;
CREATE TABLE customers ( … );
CREATE TABLE invoices  ( … );
COMMIT;
```

Either both tables exist or neither does. A migration that fails halfway leaves nothing behind —
no half-created schema for the next person to reconcile by hand. **MySQL does not do this**: each
DDL statement commits implicitly, so a failed migration leaves whatever ran before the failure.
Lesson 12 has the differences; it matters here because it changes how carefully a migration has to
be written.

## What the statement cannot say

Three things belong to a table and are not in `CREATE TABLE`, so they are separate statements and
easy to forget:

```sql
COMMENT ON TABLE invoices IS 'One row per invoice issued. Never deleted; cancelled is a status.';
COMMENT ON COLUMN invoices.total IS 'Sum of the lines at the moment of issue. Not recomputed.';

CREATE INDEX invoices_customer_id_idx ON invoices (customer_id);

GRANT SELECT ON invoices TO reporting;
```

**`COMMENT ON` is underused and costs nothing.** It is stored in the database, it shows up in
`\d+`, and it survives every person who worked here. The second one above is the `snapshot` rule
from lesson 2, written where somebody will find it.

The index is lesson 9's subject, and it is mentioned here for one reason: **a foreign key does not
create an index on itself.** The reference is a rule about what may be stored; finding the invoices
of one customer quickly is a separate thing you have to ask for.
