---
title: Serializable, and the rule two transactions broke together
version: 1
---

The shop has a rule: **a customer may have at most one pending order at a time.** It is checked in
the application, the obvious way: count the customer's pending orders, and insert the new one only
if the count is zero. Nothing in the schema enforces it.

Each transaction that runs that check is correct on its own. The belief to drop is that a strict
enough isolation level makes a check like that safe. `REPEATABLE READ` does not, and the reason is
worth seeing: **two transactions can each read, each decide, and each write a different row**,
and no row is ever written twice. This is **write skew**, and it is the anomaly only
`SERIALIZABLE` catches.

## Two orders, both allowed

Customer 7 places an order from a phone and from a laptop at the same moment. Each request runs
the check in its own `REPEATABLE READ` transaction. In window A:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.344 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 1.618 ms
```

And in window B:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.263 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 1.643 ms
```

Both see zero pending orders, so both go ahead: window A inserts, window B inserts, and then
both commit, window A first:

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 2.084 ms

market=*# COMMIT;
COMMIT
Time: 1.087 ms
```

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 1.425 ms

market=*# COMMIT;
COMMIT
Time: 0.713 ms
```

And the rule:

```
market=# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     2
(1 row)

Time: 0.579 ms
```

**Two pending orders, and neither transaction did anything wrong.** Each read a snapshot in which
the count was zero. Each inserted a new row, so nobody overwrote anything, and `REPEATABLE READ`
had nothing to refuse. The order in which the two ran made no difference: no ordering of them, one
after the other, would have produced two pending orders, and that is the definition of the
problem. The result could not have come from running them one at a time.

Remove the two orders before trying again; in window A, `DELETE FROM orders WHERE customer_id = 7
AND status = 'pending';` deleted both.

## The same two, serialisable

`SERIALIZABLE` promises exactly what the last paragraph said was missing: **the result of
transactions run together is one that running them one after the other, in some order, could have
produced.** If it cannot keep that promise, it fails one of them.

Run the same thing with `BEGIN ISOLATION LEVEL SERIALIZABLE`. In window B, first ask psql to show
the full error, with `\set VERBOSITY verbose`, so that the code is visible:

```
market=# BEGIN ISOLATION LEVEL SERIALIZABLE;
BEGIN
Time: 0.300 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 0.904 ms
```

```
market=# \set VERBOSITY verbose
market=# BEGIN ISOLATION LEVEL SERIALIZABLE;
BEGIN
Time: 0.421 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 0.572 ms
```

Again window A inserts, window B inserts, and both commit, window A first:

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 1.885 ms

market=*# COMMIT;
COMMIT
Time: 0.954 ms
```

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 1.924 ms

market=*# COMMIT;
ERROR:  40001: could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if retried.
LOCATION:  PreCommit_CheckForSerializationFailure, predicate.c:4662
Time: 0.460 ms
```

```
market=# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     1
(1 row)

Time: 0.500 ms
```

**One pending order: the rule held.** Window B's `COMMIT` failed with SQLSTATE **`40001`**,
`could not serialize access due to read/write dependencies among transactions`, and its insert was
rolled back with the rest of its transaction. The `HINT` says the useful thing: **the transaction
might succeed if retried.** Run again, window B's count would see window A's order, find one, and
refuse the second order the way the application meant to.

## How the server knew

No row was written twice, so row locks cannot have caught it. `SERIALIZABLE` in PostgreSQL also
records **what each transaction read**, as predicate locks that block nobody: window A's count read
the index entries for customer 7, and so did window B's.
Each then inserted into that same part. The server saw that A had read something B changed and B
had read something A changed, which is a cycle no serial order can explain, and it refused the
transaction whose commit would have completed the cycle. The `DETAIL` line's "pivot" is that
transaction.

## What each level costs

| level | what it prevents | how it fails |
|---|---|---|
| `READ COMMITTED` | reading uncommitted data | it does not: lost updates and write skew go through silently |
| `REPEATABLE READ` | changes appearing mid-transaction, lost updates | 40001 when a row it would write was changed after its snapshot |
| `SERIALIZABLE` | every anomaly, write skew included | 40001 whenever a cycle of reads and writes is found |

The price of the stronger levels is paid in two places. **Failures**: every 40001 is a transaction
done twice, and section 05 of this lesson measures how many. **Bookkeeping**: `SERIALIZABLE` keeps
predicate locks for every transaction, which costs memory and some CPU, and when the server cannot
track reads precisely it widens them, from a few rows to a page to a whole table, and refuses more
transactions than strictly necessary. Those refusals are false positives, and they are safe: a
retry fixes them.

Two habits keep that cost down. Use `SERIALIZABLE` for the transactions whose correctness depends
on what they read, not by default for everything. And keep those transactions short, because a
long one collects dependencies the way a long transaction in lesson 12 collected locks. For the
rule in this section there is also a simpler fix that needs no special level: **a partial unique
index**, on `customer_id` where `status = 'pending'`, lesson 9's kind, turns the rule into one the
schema enforces, and the second insert fails with a unique violation whatever the isolation level.
