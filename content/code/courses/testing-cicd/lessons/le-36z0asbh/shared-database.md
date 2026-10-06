---
title: When the database is shared
version: 1
---

`shipquote` can give every test its own SQLite file because SQLite is a file. A PostgreSQL server
is different: starting one per test takes seconds, so a suite usually shares one server, and often
one database, across every test. Then isolation stops being free and has to be designed. There are
three common designs, and the repository this course is published from uses the third.

## One transaction per test, rolled back

The fixture opens a transaction before the test and rolls it back afterwards, so nothing the test
wrote survives:

```python
@pytest.fixture
def db(connection):
    tx = connection.begin()
    yield connection
    tx.rollback()
```

This sketch is not part of `shipquote`, and it shows the shape rather than any one library. It is
fast, because a rollback costs almost nothing. It breaks when the code under test commits on its
own, opens a second connection that cannot see the uncommitted rows, or relies on something that
only happens at commit, such as a deferred constraint.

## A fresh schema per test run

Create an empty database, or a schema with a random name, when the suite starts, migrate it, and
drop it at the end. Every test in the run shares it, and the runs do not share anything with each
other. It is simple and catches commit-time behaviour, at the price of tests within one run seeing
each other's rows.

## Tests that only look at their own rows

The third design accepts that the database is shared and writes every test so that **it does not
matter who else is there**. This repository's own `CLAUDE.md` states it as three rules, under the
heading *A test does not own the database*, because `go test` runs packages in parallel against
one PostgreSQL:

> - **Never `TRUNCATE` a shared table.** It is not tidying up, it is deleting another package's
>   rows halfway through its run.
> - **Never seed a fixed unique value.** Two packages inserting the school `code` collide on the
>   unique index, and which one loses is a matter of timing.
> - **Scope every assertion to the rows the test wrote** — `WHERE tenant_id = $1`, not
>   `count(*)`.

The same file says how the rules were learnt: a duplicate key raised in two packages at once in CI,
after passing locally on timing alone. **A suite that passes by luck is worse than one that fails**,
because the luck runs out on somebody else's push.

## How this maps to shipquote

`test_recent_lists_the_newest_first` from lesson 1 already follows the third rule without needing
to: it asserts `recent(2) == [second, first]`, using the ids it got back, rather than asserting how
many rows the table holds. The failing test in section 03, `recent(10) == []`, broke it, and it
broke exactly when the database became shared. A test written to its own rows survives a change of
fixture scope; a test written to the whole table does not.

The factories in the next section help with the second rule too: a value that must be unique is
generated, not typed.
