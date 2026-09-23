---
title: Defaults, and columns the database fills in
version: 2
---

Two ways to have the database write a value so nobody has to, and they are not the same thing.

## `DEFAULT`

```sql
issued_on    date        NOT NULL DEFAULT current_date,
status       text        NOT NULL DEFAULT 'draft',
created_at   timestamptz NOT NULL DEFAULT now(),
tags         text[]      NOT NULL DEFAULT '{}'
```

A default applies **only when the column is left out of the insert**, and that is worth being
precise about, because it is the source of a common surprise:

```sql
INSERT INTO invoices (customer_id) VALUES (1);              -- status is 'draft'
INSERT INTO invoices (customer_id, status) VALUES (1, NULL); -- status is NULL
```

The second one does not get the default. It supplied a value, and the value was `NULL` — so with a
`NOT NULL` column it is refused, and without one the row is stored with an unknown status. An ORM
that sends every column on every insert never gets a default at all, which is why lesson 11's
subject reaches back into this one.

**Defaults are evaluated per row, at insert time.** `now()` is the transaction's start, so every
row of one insert gets the same timestamp — coherent by design.

**And `DEFAULT` is not a constraint.** It fills a gap and refuses nothing. `NOT NULL DEFAULT 0`
is two separate statements about the column: one says it may not be empty, the other says what to
put there if you did not say.

## Generated columns

```sql
total_gross numeric(12,2) GENERATED ALWAYS AS (total * (1 + tax_rate)) STORED
```

A generated column is **computed from other columns of the same row**, every time the row is
written, and it cannot be written to directly. An insert or update that tries is refused.

This is the one place in this course where storing a derived value is unambiguously safe, and the
reason is exactly lesson 2's fourth gate: **the mechanism that keeps it correct is the database
itself, and there is only one of it.** No trigger to write, no code path to remember, no way for
the value to drift.

The rules, and they are tighter than people expect:

- it may read **only columns of the same row** — no subqueries, no other tables;
- the expression must be deterministic, so `now()` and `random()` are refused;
- `STORED` is required in PostgreSQL; virtual generated columns, computed on read, are a MySQL
  and SQLite feature and arrived in PostgreSQL 18.

**Where it earns its keep**: a normalised search column beside the real one.

```sql
email        text NOT NULL,
email_folded text GENERATED ALWAYS AS (lower(email)) STORED UNIQUE
```

Now the uniqueness is case-insensitive, there is one place the folding happens, and no insert can
bypass it. Compare that with doing it in the application, where it holds until the import script.

## `DEFAULT` against `GENERATED`, decided in one line

> **`DEFAULT` sets a value once and the row owns it afterwards. `GENERATED` computes the value
> forever and the row never owns it.**

`created_at DEFAULT now()` is right — the moment it was created is a fact about that row and must
not change when the row is updated.

`total_gross GENERATED AS (…)` is right — it is not a fact about the row at all, it is arithmetic
on facts that are. Change the tax rate on the row and the gross follows, which is what you want,
and is precisely what you would **not** want for lesson 2's `unit_price`.

The two sections of lesson 2 are still the test: if the value should follow its source, the
database can maintain it. If it must not follow — a price on the day, an address a parcel went to
— it is a snapshot, and a `DEFAULT` that captures it once is how you say so.

## `updated_at`, and why it is not on this list

You will want one, and neither mechanism gives it to you. A `DEFAULT` sets it at insert and never
again. A generated column cannot use `now()`, because that is not deterministic.

The only correct way is a trigger:

```sql
CREATE FUNCTION touch_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER invoices_touch
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
```

It is worth doing it this way rather than in the application, for the reason lesson 1 gave about
constraints: the application is never one application, and an `updated_at` that some writers
maintain and others do not is worse than not having one, because it looks trustworthy.
