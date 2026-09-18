---
title: Reads, transactions, and one error you will meet
version: 1
---

Lesson 8 built the vocabulary: the anomalies, the isolation levels, what a transaction promises.
Oracle implements that vocabulary with a few real differences, and one of them produces an error
message specific enough to be worth recognising on sight.

## There is no read uncommitted, and there never was

Oracle offers **read committed**, which is the default, and **serializable**. It does not offer
read uncommitted at all, and it cannot: a reader never sees another transaction's uncommitted
work, because of how reads are served.

Every change is written to an **undo** area before the block is modified, so the previous version
of a row is always available. A query that starts at a given moment reads the data **as it was at
that moment**, reconstructing older versions from undo wherever a block has moved on. Oracle calls
this read consistency, and the practical guarantee is the one lesson 8 wanted:

> **A reader never blocks a writer and a writer never blocks a reader.** A long report sees a
> consistent picture of the database as of when it started, however much changes underneath it.

PostgreSQL reaches the same guarantee by a different route — it keeps old row versions in the
table itself and `VACUUM` removes them — and MySQL's InnoDB uses an undo log much as Oracle does.
The behaviour a developer sees is the same in all three.

## `ORA-01555: snapshot too old`

This is the error that undo produces, and recognising it saves an afternoon.

A report runs for two hours. Its reads are being served as of when it started, from undo. Undo is
a finite space that is being recycled by everything else the system is doing. If the version a
long query needs has been overwritten, Oracle cannot construct the answer it promised — **and it
refuses rather than returning a wrong one.** That refusal is `ORA-01555`.

The message reads, in substance, that a snapshot is too old and that rollback segment data for a
given number is no longer available. It is a documented message rather than one captured here, and
the shape is what to recognise: **a long-running query that fails partway through, with a number
in it.**

Three things follow, and the first is the useful one:

**It is not a bug in the query.** The query was correct and the system could not keep its promise.
A rewrite that makes the query faster fixes it; a retry may also work, on a quieter system.

**It is a sizing problem for whoever runs the database.** More undo, or a longer retention. That is
the DBA's to change and worth reporting to them with the statement and the time it started.

**It is an argument against very long transactions**, which is the argument lesson 8 already made
for a different reason. A report that reads for two hours is exposed to this; the same report
split by month is not.

## DDL commits, as it does on MySQL

Lesson 12 captured MySQL keeping a column that had been added inside a rolled-back transaction.
Oracle behaves the same way: **`CREATE`, `ALTER`, `DROP` and `TRUNCATE` issue an implicit commit
before and after themselves.** A transaction in progress when you run one is committed, including
the part you had not decided about yet.

So the migration rule from lesson 11 is the Oracle rule too: **one reversible step at a time, and
a tool that can resume**, because a script of six `ALTER TABLE`s that fails on the fourth has
applied three of them.

## Locking, and the one thing to write down

Row locks are held until commit or rollback, as everywhere else in this course, and a writer blocks
a writer on the same row. `SELECT … FOR UPDATE` takes the lock explicitly, which the procedure in
the last section used. `FOR UPDATE NOWAIT` fails immediately rather than waiting, and that is often
what a screen wants: a user told "somebody else is editing this" is better served than one watching
a spinner.

Deadlocks are detected and one transaction is chosen and rolled back with `ORA-00060`. **Lesson 8's
rule is unchanged: take locks in a consistent order, and be ready to retry.**

## One transaction-shaped surprise

**Oracle has no autocommit at the server.** Every statement opens a transaction and it stays open
until `COMMIT` or `ROLLBACK`. Clients differ on whether they send a commit for you — SQL\*Plus does
not by default, and many drivers do — so a session left with an uncommitted `UPDATE` holds its row
locks until somebody notices.

That is the source of a classic support call: an application hangs, the DBA finds it waiting on a
lock, and the lock is held by a colleague who ran an `UPDATE` in a client window before lunch and
did not commit. The habit worth having on Oracle is to **finish what you start in a client
window**, every time, with a `COMMIT` or a `ROLLBACK`.
