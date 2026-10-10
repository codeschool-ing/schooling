---
title: The horizon, and the one transaction that holds it
version: 1
---

The belief this section replaces is a reasonable one: **a transaction that does nothing costs
nothing.** It holds no lock anybody wants, it reads no rows, its connection sits there quietly. The
truth is that an open transaction can be the most expensive thing on the server while doing nothing
at all, because of what it stops the server from throwing away.

## Every update leaves a copy behind

PostgreSQL never changes a row where it lies. An `UPDATE` writes a **new version** of the row and
marks the old one as ended by the transaction that updated it; a `DELETE` only does the marking.
The old version stays in the table, taking its space, because somebody may still need to see it: a
transaction that started before the update must go on reading the row as it was. That is how
readers and writers avoid blocking each other, and `sql-databases` and `db-administration` both
take it for granted. What it costs is that **somebody has to come back and remove the old
versions**, and that somebody is `VACUUM`.

`VACUUM` can only remove a version that nobody can see any more. To decide that, it asks the oldest
**snapshot** still in use on the server: a snapshot is a transaction's picture of which other
transactions had committed when it looked. Every version that ended before the oldest snapshot was
taken is invisible to everybody, and can go. Every version that ended after it has to stay, in case
that snapshot's owner asks for it. That dividing line is the **horizon**, and the server moves it
forward only as fast as its oldest snapshot lets it.

## Holding it, on purpose

You need two terminals. In the first, call it **Session A**, open a transaction at `REPEATABLE
READ`, which takes one snapshot at its first query and keeps it to the end, and read something:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.833 ms

market=*# SELECT sum(price_cents) FROM products;
    sum     
------------
 1279989100
(1 row)

Time: 9.859 ms
```

Then leave Session A alone. In the second terminal, **Session B**, change one product's price and ask
`VACUUM` to clean the table. `VERBOSE` makes it say what it did:

```
market=# UPDATE products SET price_cents = price_cents + 100 WHERE id = 7;
UPDATE 1
Time: 3.669 ms

market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 0
pages: 0 removed, 649 remain, 2 scanned (0.31% of total)
tuples: 0 removed, 50001 remain, 1 are dead but not yet removable
removable cutoff: 1098934, which was 2 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 64.212 MB/s
buffer usage: 26 hits, 0 misses, 3 dirtied
```

The report goes on with the same lines for the table's TOAST storage, where long values are kept;
the lines above are the table itself. The `UPDATE` made one old version, and `VACUUM` found it and
**did not remove it**: `1 are dead but not yet removable`. The line below says why. The
`removable cutoff` is the horizon, transaction `1098934`, and it is `2 XIDs old`: two
transactions have taken a number since, the `UPDATE` among them, and the server is not allowed to
forget anything that came after the cutoff.

Who is holding it? `pg_stat_activity` has a row per connection, and its `backend_xmin` column is the
horizon each one is holding back:

```
market=# SELECT pid, state, backend_xmin, age(backend_xmin) FROM pg_stat_activity WHERE backend_xmin IS NOT NULL AND pid <> pg_backend_pid();
 pid |        state        | backend_xmin | age 
-----+---------------------+--------------+-----
 557 | idle in transaction |      1098934 |   2
(1 row)

Time: 30.577 ms
```

One session, **idle in transaction**, holding transaction `1098934`. That is Session A: it has asked
nothing for several seconds, it will not ask anything until somebody types at it, and it is the
reason the dead version stays. Go back to Session A and read the same total again, then commit:

```
market=*# SELECT sum(price_cents) FROM products;
    sum     
------------
 1279989100
(1 row)

Time: 10.726 ms

market=*# COMMIT;
```

The total is **the same as before**, although Session B added a hundred cents to product 7 in the
meantime. That is `REPEATABLE READ` doing what it promises, and it is exactly why `VACUUM` could not
remove the old version: Session A was still entitled to read it, and did. With the transaction
over, run the same `VACUUM` in Session B:

```
market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 0
pages: 0 removed, 649 remain, 2 scanned (0.31% of total)
tuples: 1 removed, 50000 remain, 0 are dead but not yet removable
removable cutoff: 1098936, which was 0 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan bypassed: 1 pages from table (0.15% of total) have 1 dead item identifiers
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 55 hits, 0 misses, 0 dirtied
WAL usage: 3 records, 1 full page images, 8501 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
INFO:  vacuuming "market.pg_toast.pg_toast_16498"
INFO:  finished vacuuming "market.pg_toast.pg_toast_16498": index scans: 0
```

`1 removed`, and the cutoff has moved on to `1098936`, the newest transaction there is, because
nobody is behind it any more.

## What holds a horizon, and what does not

Session A held it with an explicit `REPEATABLE READ`, which is the clearest way to see it. Three
other things hold it in ordinary applications, and section 05 of this lesson finds each of them in
`pg_stat_activity`:

- **A transaction that has written something** and not finished. Its own transaction number is in
  `backend_xid`, and every version made after it has to wait, whatever the isolation level. The
  application that opens a transaction, updates an order and then calls a payment service before
  committing does this on every purchase.
- **A statement that is still running.** A report that takes twenty minutes holds its snapshot for
  twenty minutes, and so does a `pg_dump`, which reads the whole database in one snapshot so that its
  copy is consistent.
- **A cursor or a long `REPEATABLE READ` transaction** an analyst opened in a client and walked away
  from.

What does **not** hold it is an idle transaction at the default level, `READ COMMITTED`, that has
only read: it takes a fresh snapshot for each statement and lets go of it when the statement ends.
Lesson 14 is where the two levels' other differences live; here only this one matters.

The horizon is also **the database's, not the table's**. Session A read `products`, but a session
holding the horizon stops `VACUUM` from cleaning every table in the database, including the ones it
has never touched. The next section measures what that does to a table under steady updates.
