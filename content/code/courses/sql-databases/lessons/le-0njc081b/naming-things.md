---
title: Naming your constraints, before the database names them
version: 2
---

Every constraint has a name. If you do not give it one, PostgreSQL invents one, and the invented
name is the reason this section exists.

```sql
CREATE TABLE invoices (
    number text NOT NULL UNIQUE,
    total  numeric(12,2) NOT NULL CHECK (total >= 0)
);
```

```
Indexes:
    "invoices_number_key" UNIQUE CONSTRAINT, btree (number)
Check constraints:
    "invoices_total_check" CHECK (total >= 0)
```

Reasonable names, and they cost you twice.

## The first cost: what a person sees

An application catches a constraint violation and has to turn it into a sentence. What it gets is:

```
ERROR:  duplicate key value violates unique constraint "invoices_number_key"
```

`invoices_number_key` is a name a program can match on, so the application says *"that invoice
number is already in use"* by comparing against that string. It works — until a table has two
`CHECK`s on the same column:

```
"invoices_total_check"    CHECK (total >= 0)
"invoices_total_check1"   CHECK (total < 1000000)
```

**The `1` is positional.** Which rule is which depends on the order they were declared, and a
migration that drops and re-adds one can renumber them. The application's message is now attached
to a name that moved, and it reports the wrong rule with complete confidence.

## The second cost: dropping something you cannot name

```sql
ALTER TABLE invoices DROP CONSTRAINT invoices_total_check1;
```

Fine, until you have to write that migration against a database where the generated name is
different — because the constraints were added in a different order on staging, or because an
older version of PostgreSQL numbered differently. **The migration passes on one database and fails
on another**, which is the worst kind of failure a migration has.

## So name them

```sql
CREATE TABLE invoices (
    id          bigint GENERATED ALWAYS AS IDENTITY,
    customer_id bigint NOT NULL,
    number      text   NOT NULL,
    total       numeric(12,2) NOT NULL,
    paid_at     timestamptz,

    CONSTRAINT invoices_pk           PRIMARY KEY (id),
    CONSTRAINT invoices_number_uq    UNIQUE (number),
    CONSTRAINT invoices_customer_fk  FOREIGN KEY (customer_id)
                                     REFERENCES customers (id) ON DELETE RESTRICT,
    CONSTRAINT invoices_total_not_negative CHECK (total >= 0),
    CONSTRAINT invoices_total_sane         CHECK (total < 1000000)
);
```

Now the error message names the rule rather than the column, and it stays that name forever:

```
ERROR:  new row for relation "invoices" violates check constraint "invoices_total_not_negative"
```

A person reading that knows what went wrong without opening the schema. A program matching on it
is matching on something somebody chose.

## A convention that holds up

| suffix | for |
|---|---|
| `_pk` | primary key |
| `_uq` | unique |
| `_fk` | foreign key |
| `_ck` or a sentence | check |

For checks, **a sentence beats a suffix**. `invoices_total_not_negative` says what is wrong;
`invoices_total_ck2` says which one it was. The name is the error message the user's user
eventually sees, one layer removed, so write it as though somebody will read it — because they
will.

## The counter-argument, stated fairly

Naming every constraint is more to type, and on a table with four columns and two rules the
generated names are perfectly clear. Plenty of good schemas do not do this.

Where it stops being optional:

- **when more than one `CHECK` touches a column**, because that is where the positional numbering
  starts;
- **when the application turns violations into messages**, because it is matching on the name;
- **when migrations must run identically on several databases**, which is every deployed system.

If none of those is true yet, all three become true later, and adding names afterwards means a
migration per constraint. It is one of the few habits in this lesson that costs nothing now and
cannot be retrofitted cheaply.

## While you are here: `COMMENT ON`

```sql
COMMENT ON CONSTRAINT invoices_total_sane ON invoices IS
    'A guard against a misplaced decimal point, not a business limit.';
```

A constraint says what is refused. A comment says why, which is the thing somebody needs when they
hit it at three in the morning and are deciding whether to remove it.
