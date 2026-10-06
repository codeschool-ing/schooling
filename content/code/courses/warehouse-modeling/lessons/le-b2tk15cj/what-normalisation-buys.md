---
title: What normalisation buys, and for whom
version: 1
---

`sql-databases` lesson 2 took a table apart until every fact lived in one place, and called the
result third normal form. Its argument was about **anomalies**, three ways a table with repeated
values goes wrong when it is written to:

- **An update anomaly.** A department's name is written in a thousand rows. Renaming it means updating
  a thousand rows, and if the update stops halfway, the table holds two names for one department.
- **An insertion anomaly.** A fact cannot be recorded without an unrelated one. If department names only
  exist on book rows, a new department cannot be created until it has a book.
- **A deletion anomaly.** Deleting the last book of a department deletes the only record that the
  department existed.

**Every one of those is about writing.** Normalisation is a design for a database that many people
change, a row at a time, at unpredictable moments, where any single statement may be the one that
fails. That is exactly lesson 1's operational database, and in it, normalisation is right.

The warehouse is written differently:

- **One writer.** The load is the only thing that changes it. No person updates a department name by
  hand, and no till writes to it.
- **In batches, from a single source.** `dim_book` is rebuilt from the operational database's one copy
  of each name, so every row gets the same name in the same statement.
- **Inside a transaction.** A load that fails rolls back, and the warehouse stays as it was, rather
  than half old and half new.

So the anomalies normalisation prevents cannot happen in the way they happen to an operational
database. What is left of the trade-off is the reading side, and on the reading side, repetition is
cheap and joins are not free. The next sections put numbers on both.
