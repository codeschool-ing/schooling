---
title: Advisory locks, for things that are not rows
version: 1
---

Every lock so far protected something the database knows about: a table, a row. Sometimes what
needs protecting is a piece of work. The nightly recount of every seller's orders must run once,
but it is started by a scheduler on each of three application servers, because nobody wants the
job to depend on one machine being up. Nothing in the data says "the recount is running", and a
`status` row to say it is the wrong tool: a worker that crashes after setting it leaves it set,
and the job never runs again until a person notices.

**An advisory lock is a lock on a number.** The database attaches no meaning to it; your code
decides that number 42, or the hash of the string `nightly-recount`, means "the recount". The
server only guarantees that two sessions cannot hold the same number at the same time, and that a
session's locks are released when the session ends, however it ends.

## Taking one, and failing to

In window A:

```
market=# SELECT pg_try_advisory_lock(42);
 pg_try_advisory_lock 
----------------------
 t
(1 row)

Time: 1.248 ms
```

In window B, the same number:

```
market=# SELECT pg_try_advisory_lock(42);
 pg_try_advisory_lock 
----------------------
 f
(1 row)

Time: 1.008 ms

market=# SELECT pg_advisory_lock(42);
```

`pg_try_advisory_lock` answers at once, `t` or `f`, and never waits: window A got lock 42 and window
B was told no. `pg_advisory_lock`, without `try`, waits like any other lock, and window B is waiting
now. Release it in window A:

```
market=# SELECT pg_advisory_unlock(42);
 pg_advisory_unlock 
--------------------
 t
(1 row)

Time: 0.927 ms
```

```
market=# SELECT pg_advisory_lock(42);
 pg_advisory_lock 
------------------
 
(1 row)

Time: 6487.695 ms (00:06.488)
```

Window B had waited **6434 ms**, and the lock passed to it the moment window A let go. Release it
in window B too with `SELECT pg_advisory_unlock(42);`.

These are **session-level** locks: they last until they are unlocked or the session disconnects,
whatever happens to transactions in between, and the same session can take the same number twice
and must then unlock it twice. The `pg_advisory_xact_lock` family is the **transaction-level**
version, released at `COMMIT` or `ROLLBACK` and impossible to unlock by hand; it is the safer
choice when the work fits in one transaction, because there is no unlock to forget.

## A job only one worker runs

The scheduler on each server runs this file with `psql`. It asks for the lock without waiting,
does the work if it got it, and says so if it did not, using psql's own `\if`:

```sh
cat > ~/nightly-job.sql <<'SQL'
-- nightly-job.sql: the nightly recount, started by every worker at 02:00
-- and done by exactly one of them. The others find the lock taken.
SELECT pg_try_advisory_lock(hashtext('nightly-recount')) AS got_it \gset
\if :got_it
  \echo 'this worker runs the nightly recount'
  -- the recount itself; pg_sleep stands in for it here
  SELECT pg_sleep(5) \g /dev/null
  \echo 'done'
\else
  \echo 'another worker holds the lock: nothing to do'
\endif
SQL
```

`hashtext` turns the job's name into the number, so the code reads as a name and two different jobs
do not collide by somebody reusing 42. `\gset` puts the answer, `t` or `f`, into the psql variable
`got_it`, and `\if` branches on it. There is no unlock at the end on purpose: the lock goes when
psql disconnects at the end of the file, and it also goes if psql is killed halfway, which is
exactly the case the `status` row got wrong.

Start two workers a second apart, the way two schedulers whose clocks differ slightly would:

```
ana@vm:~$ psql -qX market -f nightly-job.sql & sleep 1; psql -qX market -f nightly-job.sql; wait
this worker runs the nightly recount
another worker holds the lock: nothing to do
done
```

The first worker took the lock and ran; the second, a second later, found it held and left at
once; the first finished five seconds after it started. **One recount, whichever worker got there
first, and no row anywhere that a crash could leave behind.**

## What to watch for

**The lock belongs to a connection.** Behind a connection pooler in transaction mode (lesson 16), a
session-level advisory lock is taken on whichever server connection the pooler handed out for that
transaction. The next transaction may get a different one, and the lock is left held on a
connection your code no longer has. Use the transaction-level functions there, or a connection of
the job's own.

**The number space is shared by the whole database.** Every advisory lock on `market` uses the same
numbers, so two teams who both pick 42 lock each other out. Hash a name, as the file does, or use
the two-argument form, `pg_advisory_lock(class, id)`, with one class number per kind of work.

**They show up in `pg_locks`** with `locktype` `advisory`, which is how lesson 13 finds the session
holding one when a job seems stuck.
