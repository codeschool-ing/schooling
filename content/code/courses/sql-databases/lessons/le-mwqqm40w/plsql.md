---
title: PL/SQL, and why the logic is in the database
version: 1
---

Open a twenty-year-old corporate Oracle system and a great deal of what an application developer
would expect to find in application code is inside the database instead: validation, workflow,
batch processing, reporting, sometimes the whole of a business process. That is not laziness and
it is not a mistake somebody made. It is PL/SQL, and there were reasons.

## What PL/SQL is

A procedural programming language that runs inside the database server. It has variables, loops,
conditionals, exceptions and procedures, and SQL statements are part of its syntax rather than
strings passed to a driver:

```sql
CREATE OR REPLACE PROCEDURE cancel_order (p_order_id IN NUMBER) IS
  v_status  orders.status%TYPE;
BEGIN
  SELECT status INTO v_status FROM orders WHERE id = p_order_id FOR UPDATE;

  IF v_status = 'shipped' THEN
    RAISE_APPLICATION_ERROR(-20001, 'a shipped order cannot be cancelled');
  END IF;

  UPDATE orders SET status = 'cancelled' WHERE id = p_order_id;
  INSERT INTO order_events (order_id, kind) VALUES (p_order_id, 'cancelled');
  COMMIT;
END;
```

Three things in that block are worth naming, because they are what the language is for.

**`orders.status%TYPE`** declares the variable as whatever the column's type is. Change the column
and the procedure follows, which is the opposite of the drift lesson 11 described between a class
and a table.

**`SELECT … INTO`** puts a single row into variables, and raises `NO_DATA_FOUND` if there is none
and `TOO_MANY_ROWS` if there is more than one. A whole class of silent wrongness is an exception
here.

**The transaction is the procedure's.** The `UPDATE` and the `INSERT` are one transaction, and
lesson 8's guarantee holds over the pair. Nothing crosses a network between them.

## Packages, which are the unit that matters

A **package** is a named group of procedures and functions with a specification and a body,
compiled and stored in the database:

```sql
CREATE OR REPLACE PACKAGE orders_api AS
  PROCEDURE cancel (p_order_id IN NUMBER);
  FUNCTION  total  (p_order_id IN NUMBER) RETURN NUMBER;
END orders_api;
```

The specification is the interface and the body is private, so a package is a module with a
boundary. A corporate system's *API* is often a set of packages, and the application — in Java, in
.NET, in COBOL — calls `orders_api.cancel(42)` and does not write SQL at all.

## Why it was built that way

Four reasons, and three of them were good at the time:

**One place for a rule.** Six applications and a nightly batch all reach the same tables. A rule in
the database is a rule for all of them; a rule in one application is a rule for one of them. This
is the same argument lesson 11 made for a constraint over a class validation, taken further.

**No round trips.** A loop over ten thousand rows that runs inside the server does not send ten
thousand statements across a network. This is the N+1 problem of lesson 11 solved by moving the
loop rather than by fixing the query, and on the hardware of 1998 it was a large win.

**The licence is already paid.** The database is the expensive machine and it is bought. Work done
there is work on hardware the organisation owns, and the section before this one is why that
argument keeps being made.

**And one that was not good:** it was what the tooling encouraged. Oracle Forms and the generation
of tools built on it assumed the database was where logic lived, and a great deal of PL/SQL exists
because that was the path of least resistance rather than because anybody weighed it.

## What it costs

Worth stating plainly, because a developer arriving today will feel all four:

**It is hard to test.** A package runs in a database with state. Unit-testing it means a framework
such as utPLSQL and a database to run against, which is a much heavier loop than the application's.

**It is hard to review.** The deployed version lives in the database. Keeping the source in git and
the database in step is a discipline, not a property, and a system where somebody has compiled a
change directly is a system where git is wrong and nothing says so.

**It is one vendor's language.** Lesson 12's SQL is portable and PL/SQL is not. A system whose
logic is in packages is a system whose migration cost is the logic, which is the last section's
subject.

**The people are scarcer.** Hiring somebody who writes PL/SQL well is harder every year, and that
is a real risk to a system rather than a matter of taste.

## What to do with it

If you join a system built this way, **the packages are the documentation of the business**, and
they are usually better documentation than anything written down. Read them.

Do not try to move the logic out because it is unfashionable. Move a piece of it when there is a
reason — a rule that changes often, a workflow that wants to be tested — and leave the rest. And
whatever you do write in application code, the constraints stay in the tables: that rule is from
lesson 11 and it did not become false because there is a package beside it.
