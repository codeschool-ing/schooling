---
title: Constraints: rules the database keeps, not the application
version: 1
---

You have already met three constraints without them being called that. `PRIMARY KEY`, `REFERENCES`
and `NOT NULL` are all rules declared once in the table and enforced forever. This section names
the full set and makes the argument for putting rules here rather than in your program.

```sql
CREATE TABLE products (
    id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku          text          NOT NULL UNIQUE,
    name         text          NOT NULL,
    price        numeric(10,2) NOT NULL CHECK (price >= 0),
    stock        integer       NOT NULL DEFAULT 0 CHECK (stock >= 0),
    discontinued boolean       NOT NULL DEFAULT false
);
```

| constraint | what it refuses |
|---|---|
| `NOT NULL` | an unknown where a value is required |
| `UNIQUE` | a second row with the same value |
| `PRIMARY KEY` | both of the above, and names the row |
| `REFERENCES` | a pointer to something that is not there |
| `CHECK (…)` | anything that makes the expression false |
| `DEFAULT …` | nothing — it fills a value in when the insert leaves it out |

`DEFAULT` is in the table because it is written in the same place, but it is not a rule; it is a
convenience. The others refuse.

## `CHECK` is the general one

`CHECK` takes any expression about the row and refuses anything that makes it false:

```sql
CHECK (price >= 0)
CHECK (quantity > 0)
CHECK (ends_on > starts_on)
CHECK (status IN ('draft', 'placed', 'shipped', 'cancelled'))
CHECK (email LIKE '%@%')
```

Two details in that list are worth pausing on.

`CHECK (ends_on > starts_on)` spans **two columns of the same row**, which is allowed and useful.
What a `CHECK` may not do is look at other rows or other tables — "no more than three bookings per
customer" is not a `CHECK`, because answering it means counting rows elsewhere.

And `CHECK` follows the three-valued logic from the last section: it refuses on **false**, not on
"not true". If `ends_on` is `NULL`, the expression is unknown, and unknown is not false, so the row
is **accepted**. A `CHECK` on a nullable column is not the rule you think you wrote.

## The status column, and a decision you will meet constantly

`CHECK (status IN ('draft', 'placed', 'shipped', 'cancelled'))` is one of three ways to say the
same thing, and the choice comes up in every schema anybody builds:

| how | good | bad |
|---|---|---|
| `CHECK (… IN (…))` | one line, readable in the table | adding a value alters the table |
| an `ENUM` type | the list is reusable across tables | altering it is vendor-specific and awkward |
| a `statuses` table with a foreign key | a new status is one `INSERT`; the status can carry a label, an order, a colour | one more table, one more join |

**For a fixed list that nobody will change — `CHECK`.** Four order statuses, the days of the week,
`'M'`/`'F'`/`'X'`. The list is part of the design.

**For a list that is data — a table.** Product categories, countries, support-ticket priorities.
The giveaway is that somebody non-technical will want to add one, or that the values need
properties of their own. The moment you find yourself wanting to store a display name next to a
status, you have found out it was data.

The mistake to avoid is neither of these: a plain `text` column with no constraint at all, which
ends up holding `'shipped'`, `'Shipped'`, `'SHIPPED'` and `'shiped'`, and no query is right again.

## Why the rules go in the database

This is the section's actual argument, and it is one you will have to make to somebody eventually.

The objection is reasonable: *the application already validates this. Why say it twice?*

**Because "the application" is never one application.** By the time a database is two years old it
is being written to by the web app, a background job, an import script, a mobile API, an admin
console, a data fix somebody ran from a terminal, and whatever the analytics team built. Each of
those is a place the rule can be forgotten, and the rule is only as strong as the weakest of them.

Three more reasons, in increasing order of how much they cost when ignored:

**The application validates what it can see.** "This email is unique" is checked by selecting, then
inserting. Two requests arriving at the same moment both check, both find nothing, and both
insert. The application did everything right and the data is wrong anyway. A `UNIQUE` constraint
cannot be beaten this way, because the check and the write are one operation inside the database.

**Bad data outlives the code that made it.** Application code is replaced every few years; the data
is migrated forward, defects and all. A constraint refuses the bad row at the moment it is written,
which is the only moment it is cheap to fix — the person who caused it is still there, and there is
exactly one of them.

**A constraint is documentation that cannot be wrong.** A comment saying "price is never negative"
may be false. `CHECK (price >= 0)` is true of every row in the table, including the ones written
before you arrived, or the table would not have accepted them.

## And the honest cost

Constraints are not free, and pretending otherwise makes the argument weaker.

- **They cost a little on write.** Every insert checks them. In practice this is far smaller than
  people expect, and far smaller than the queries the bad data would have made you write.
- **They make bulk loading awkward.** Importing ten million rows with foreign keys checked one at a
  time is slow; the answer is to load, then add the constraints, which validates the whole table
  once.
- **They make some deployments harder.** Adding `NOT NULL` to a column that already has nulls
  fails, and correctly — but it fails at the worst moment unless somebody checked first. That is a
  migrations topic and it is lesson 11.
- **They are a real refusal.** `RESTRICT` blocking a delete you wanted is not a bug, but it is
  friction, and somebody will propose removing the constraint rather than asking why the delete
  was wrong.

The trade is worth making almost every time, and the reason to know the costs is so you can make
it deliberately rather than as a slogan.

## Where to start

A rule for the first schema you design, which will not steer you wrong:

> Every column `NOT NULL` unless you can describe the empty one. Every table with a primary key.
> Every reference declared. A `CHECK` wherever you catch yourself writing a comment about what a
> column may hold.

You can always relax a constraint later, on a table that obeyed it. You cannot add one later to a
table that has been quietly breaking it for two years — not without a cleanup nobody budgeted for,
which is how these get skipped in the first place.
