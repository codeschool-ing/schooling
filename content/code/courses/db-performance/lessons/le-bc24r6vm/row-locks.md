---
title: Row locks, and the queue that does not wait
version: 1
---

Table locks decide who may touch a table at all. Within a table, the waiting that happens day to
day is over **rows**: two transactions that want to change the same row cannot both have it, and
the second one waits. `sql-databases` lesson 8 introduced the clauses; this section runs each of
them on `market` with two windows, so that you see who waits, for how long, and what the waiting
one reads when it is let through.

A row lock is not stored where table locks are. PostgreSQL writes it **into the row itself**, in
the row's header, so a transaction can lock a million rows without using a million entries of
memory. The price is that `pg_locks` cannot list locked rows; lesson 13 shows what it lists
instead.

## Two writers, one row

In window A, start a transaction and change order 1:

```
market=# BEGIN;
BEGIN
Time: 0.351 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 2.694 ms
```

In window B, change a different order, read order 1, then try to lock it:

```
market=# BEGIN;
BEGIN
Time: 0.363 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 2.744 ms

market=*# SELECT status FROM orders WHERE id = 1;
  status   
-----------
 delivered
(1 row)

Time: 0.889 ms

market=*# SELECT status FROM orders WHERE id = 1 FOR UPDATE NOWAIT;
ERROR:  could not obtain lock on row in relation "orders"
Time: 0.601 ms

market=!# ROLLBACK;
ROLLBACK
Time: 0.259 ms

market=# BEGIN;
BEGIN
Time: 0.195 ms

market=*# SELECT status FROM orders WHERE id = 1 FOR UPDATE;
```

Four things happened in window B, and each is a rule.

**A different row is no conflict.** Order 2 updated in under 3 ms, next to window A's open
update. Row locks are per row, so writers on different rows of one table never wait for each
other.

**Reading is never blocked by a row lock.** The plain `SELECT` of order 1 answered at once, and
answered `delivered`: window A's change is not committed, so window B reads the version from before
it.

**`NOWAIT` refuses instead of waiting.** `FOR UPDATE` asks for the same lock an update would take,
at the moment of reading, and `NOWAIT` turns "wait" into an immediate error, `could not obtain lock
on row in relation "orders"`. The error aborted window B's transaction, which is why the prompt
turned into `market=!#` and needed a `ROLLBACK`. Use it where a person is waiting for an answer
and "somebody else is editing this" is a better answer than a spinner.

**Without `NOWAIT`, it waits.** The last `SELECT … FOR UPDATE` printed nothing. Now commit window
A:

```
market=*# COMMIT;
COMMIT
Time: 153.469 ms
```

```
market=*# SELECT status FROM orders WHERE id = 1 FOR UPDATE;
 status  
---------
 shipped
(1 row)

Time: 7084.975 ms (00:07.085)
```

Window B got the lock after **7085 ms** of waiting, and read `shipped`, not `delivered`. **A
locking read returns the row as it is when the lock is granted**, after the other transaction's
change, which is what makes `SELECT … FOR UPDATE` followed by an `UPDATE` safe against the lost
update lesson 14 measures. Roll window B back with `ROLLBACK;` before going on.

## Sharing a lock

`FOR SHARE` is the weaker lock: many transactions can hold it on the same row at once, and it
keeps the row from being changed while they do. In window A:

```
market=# BEGIN;
BEGIN
Time: 0.213 ms

market=*# SELECT status FROM orders WHERE id = 3 FOR SHARE;
  status   
-----------
 delivered
(1 row)

Time: 0.747 ms
```

Then window B takes the same lock on the same row, which works, and tries to change the row, which
does not:

```
market=# BEGIN;
BEGIN
Time: 0.245 ms

market=*# SELECT status FROM orders WHERE id = 3 FOR SHARE;
  status   
-----------
 delivered
(1 row)

Time: 0.490 ms

market=*# UPDATE orders SET status = 'cancelled' WHERE id = 3;
```

Window B's own share lock does not let it update the row while window A also holds one. Roll window
A back:

```
market=*# ROLLBACK;
ROLLBACK
Time: 0.379 ms
```

```
market=*# UPDATE orders SET status = 'cancelled' WHERE id = 3;
UPDATE 1
Time: 5888.203 ms (00:05.888)
```

**5888 ms** of waiting, then the update. `FOR SHARE` fits a check like "this seller must still
exist while I insert their order": several transactions can make that check at once, and none of
them can delete the seller under the others. It is also the easiest way to write a deadlock: two
transactions that each hold a share lock on a row and then each try to update it wait for each
other, which is section 06 of this lesson. Roll window B back too.

## A job queue on `orders`

The warehouse packs orders, and several packing stations ask the database for work at the same
time. Each station takes the three oldest pending orders and marks them `packing`, in one
statement. In window A:

```
market=# BEGIN;
BEGIN
Time: 0.470 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;
   id    
---------
 1992683
 1992684
 1992682
(3 rows)

UPDATE 3
Time: 506.600 ms
```

In window B, a second station asks the same question at the same moment:

```
market=# BEGIN;
BEGIN
Time: 0.351 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;
```

Window B waits. The three oldest pending orders are locked by window A, and the second station
cannot skip past them. Commit window A, as a station would once its three are marked:

```
market=*# COMMIT;
COMMIT
Time: 5.076 ms
```

```
market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;
   id    
---------
 1992686
 1992687
 1992685
(3 rows)

UPDATE 3
Time: 7495.285 ms (00:07.495)
```

Window B waited **7495 ms**, then re-read the rows it had been waiting for, found they were no
longer `pending`, and took the next three. The answer is right; the stations just took turns. With
ten stations that is a queue served by one station at a time, and the more stations you add, the
longer each one waits. Roll window B back, so that its three orders are pending again.

**`SKIP LOCKED` is the fix**, and it is one clause. Run the same statement with it, in both
windows:

```
market=# BEGIN;
BEGIN
Time: 0.266 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED) RETURNING id;
   id    
---------
 1992686
 1992687
 1992685
(3 rows)

UPDATE 3
Time: 418.933 ms
```

```
market=# BEGIN;
BEGIN
Time: 0.221 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED) RETURNING id;
   id    
---------
 1992690
 1992689
 1992688
(3 rows)

UPDATE 3
Time: 427.529 ms
```

**Window B no longer waited.** It skipped the three rows window A had locked and took the next three
in 428 ms, about what window A took. That is the time to find pending orders among two million
with no index on `status`, and lesson 9's partial index is the one to build here. Each station gets
its own rows, nobody waits for anybody, and a station that crashes before committing simply
releases its rows for the next one to take. Roll both windows back.

Two warnings with it. `SKIP LOCKED` gives an inconsistent view on purpose: a report that used it
would silently miss every locked row, so it belongs in queues and nowhere else. And the lock lasts
until the station's transaction ends, so **a station must commit as soon as it has marked its
rows** and do the packing outside the transaction. A station that keeps its transaction open while
it works holds its rows, and the table's locks, for as long as the work takes.
