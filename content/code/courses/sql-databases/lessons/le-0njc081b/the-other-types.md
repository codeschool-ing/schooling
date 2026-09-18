---
title: The other types, and when each is the right answer
version: 1
---

Four more that come up constantly, and one instruction each about when to reach for it.

## `boolean`

```sql
discontinued boolean NOT NULL DEFAULT false
```

True, false, and — unless you forbid it — `NULL`. A three-state boolean is almost always an
accident, and `NOT NULL DEFAULT false` is how you get the two states you meant.

**And a boolean is often a date in disguise.** `is_paid boolean` answers whether; `paid_at
timestamptz` answers whether *and when*, in one column, with no extra cost. The second is strictly
more information, and `WHERE paid_at IS NOT NULL` reads perfectly well. Reach for the timestamp
whenever the flag marks something that happened at a moment.

Where a boolean is genuinely right: a setting somebody toggles, a property with no event behind it
— `is_active`, `newsletter_opt_in`.

## `uuid`

```sql
public_id uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE
```

128 bits, effectively unique without coordination. Two uses, and they are different:

**As a public identifier beside a small integer key.** Lesson 1's point: `/orders/1004` tells
somebody that `/orders/1003` exists and belongs to another person. A UUID in the URL says nothing.
The integer stays as the primary key because it is smaller in every index and every foreign key.

**As the primary key itself**, when rows are created by several machines that cannot ask a central
sequence — offline clients, sharded systems, data merged from several sources. The cost is real:
16 bytes instead of 4 or 8 in every index, and random UUIDs scatter inserts across the whole index
rather than appending at the end, which hurts on large tables. UUID v7, which is time-ordered,
exists to fix exactly that.

> Default to an integer key. Add a UUID when something outside the database needs to name a row,
> or when the database is not the only thing creating them.

## `enum` against a table

```sql
CREATE TYPE invoice_status AS ENUM ('draft', 'issued', 'paid', 'cancelled');
status invoice_status NOT NULL DEFAULT 'draft'
```

An `ENUM` is compact, readable, reusable across tables, and sorts in declaration order, which is
genuinely useful — `ORDER BY status` gives draft, issued, paid, cancelled.

The cost is that changing it is awkward. Adding a value is easy (`ALTER TYPE … ADD VALUE`);
**removing or renaming one is not**, and adding a value could not be done inside a transaction
until recently, which made migrations unpleasant.

Lesson 1 gave the decision and it has not changed — the third row is the one to notice:

| | when |
|---|---|
| `CHECK (… IN (…))` | a short fixed list that is part of the design |
| `ENUM` | the same list, needed in several tables, with a meaningful order |
| a table with a foreign key | the values are **data**: somebody non-technical adds one, or they need a label, a colour, an ordering of their own |

**The giveaway for the third is wanting to store something next to the value.** The moment a status
needs a display name in two languages, it was a table.

## `json` and `jsonb`

```sql
payload jsonb NOT NULL
```

`jsonb` is the one to use — it is parsed and stored in a binary form, it can be indexed, and it is
what every operator is written for. Plain `json` keeps the original text including whitespace and
key order, which matters only if you need to give back exactly what you received.

**It is right for genuinely opaque data**: a webhook payload from somebody else's API, stored as it
arrived; a per-user preferences blob nothing joins to; an audit record of what a request contained.

**It is wrong as a way to avoid designing a table.** The symptoms are specific, and if any of these
is true the thing was a table:

- you find yourself indexing a particular key inside it;
- you want a foreign key from something inside it;
- you want to ask "how many of X" across rows;
- two writers disagree about what keys exist.

A `jsonb` column is a small schemaless database inside your schema, with none of the guarantees
this course has spent three lessons building. That is a reasonable trade for a payload and a bad
one for your own domain.

## Arrays

```sql
tags text[] NOT NULL DEFAULT '{}'
```

PostgreSQL's arrays are real and useful, and lesson 2 gave the test: a list in a column is a
many-to-many somebody chose not to model.

Use one when the elements are **not things** — labels with no properties, a fixed vector of
numbers, a set nothing else references. Use a table when they are, and the sign is the same as
with `jsonb`: the moment you want to count them, join to them or constrain them, they were rows.

## And a rule that covers all five

> **Reach for the most specific type that is true of the value.**

`text` will hold a date, and a `date` column refuses `'next Tuesday'`. `jsonb` will hold a
customer, and a table refuses one with no name. Every step towards a narrower type moves a class
of error from *found in a report months later* to *refused at the moment it was written*, which is
the only trade this whole lesson is making.
