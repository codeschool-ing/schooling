---
title: Retrying is the application's job
version: 1
---

Sections 03 and 04 of this lesson ended in the same place: a transaction refused with SQLSTATE
**40001**, and a `HINT` saying it might succeed if retried. The common reaction is to treat that
as a database error, log it and return a failure to the user. **It is not an error in that
sense.** It is the server saying "this transaction lost a race and nothing it did was kept; run it
again". Under `REPEATABLE READ` or `SERIALIZABLE`, writing the retry is part of writing the
transaction, the same way the deadlock of lesson 12, SQLSTATE **40P01**, needs one.

Three rules make a retry correct:

- **Retry the whole transaction, from `BEGIN`.** The failed transaction is rolled back entirely;
  re-sending its last statement would run it with no transaction around it, on data it never read.
- **Repeat the reads too.** The point of the retry is a new snapshot. Code that read the price
  before the loop and only retries the write recreates the lost update.
- **Retry only 40001 and 40P01, a bounded number of times.** Those two mean "try again". A
  constraint violation or a syntax error would fail identically forever.

## pgbench retries, and what it costs

pgbench has the loop built in: `--max-tries` runs a transaction that fails with 40001 or 40P01
again, up to that many times. The same `price-bump.sql`, now in `SERIALIZABLE`, with up to ten
tries each:

```
market=# SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \gset
Time: 1.553 ms

market=# \! PGOPTIONS='-c default_transaction_isolation=serializable' pgbench -n -c 8 -j 4 -T 10 --max-tries=10 -f ~/workload/price-bump.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/price-bump.sql
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 10
duration: 10 s
number of transactions actually processed: 37218
number of failed transactions: 17 (0.046%)
number of transactions retried: 12509 (33.595%)
total number of retries: 20781
latency average = 2.147 ms (including failures)
initial connection time = 17.458 ms
tps = 3724.890914 (without initial connection time)

market=# SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
 cents_added 
-------------
       37218
(1 row)

Time: 0.668 ms
```

**37,218 transactions committed and the prices rose by exactly 37,218 cents.** 12,509 of them,
a third, needed more than one try, 20,781 extra tries in all, and 17 still failed after ten,
because eight clients on ten rows is a fight that some transaction loses ten times running.

Side by side, the three runs of this lesson:

| | read committed | repeatable read | serializable, 10 tries |
|---|---|---|---|
| committed | 55,802 | 49,741 | 37,218 |
| cents added | 37,821 | 49,741 | 37,218 |
| lost or failed | 17,981 lost | 28,848 failed | 17 failed |
| transactions a second | 5578 | 4975 | 3725 |

**Only the last column is both correct and finished.** `READ COMMITTED` was fastest and wrong by a
third. `REPEATABLE READ` was correct for every transaction it committed and refused a third of
them. `SERIALIZABLE` with retries committed fewer a second than either, because every retry is work
done twice, and got every one of them right but 17. Take the transaction rates as rough: on this
machine the same ten-second run moves by a large fraction between attempts, and the counts are the
part that does not. On a real workload, with thousands of rows instead of ten, conflicts are rare,
retries are a fraction of a per cent, and the cost of the stronger level is mostly the bookkeeping.

## A retry loop, in Python

An application has to do what `--max-tries` did. Here it is in Python, with **psycopg**, the
PostgreSQL driver Ubuntu packages. Install it on the virtual machine:

```
ana@vm:~$ sudo apt install -y python3-psycopg

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

Reading package lists...
Building dependency tree...
Reading state information...
python3-psycopg is already the newest version (3.1.17-2).
0 upgraded, 0 newly installed, 0 to remove and 140 not upgraded.
```

This machine already had it; yours will download it first. The program raises product 1's price by
one cent, N times, each in its own `SERIALIZABLE` transaction, and retries whatever the server
refuses. Copy it whole into `~/bump.py`:

```schooling-example
{
  "language": "python",
  "file": "bump.py",
  "parts": [
    {
      "code": "#!/usr/bin/env python3\n\"\"\"bump.py N: raise product 1's price by one cent, N times, each time in a\nSERIALIZABLE transaction, retrying whatever the server refuses to serialise.\"\"\"\nimport random\nimport sys\nimport time\n\nimport psycopg\nfrom psycopg import errors\n\n"
    },
    {
      "code": "RETRY = (errors.SerializationFailure, errors.DeadlockDetected)  # 40001, 40P01\n\n",
      "note": "**The two errors worth retrying.** Both mean \"this transaction lost a race and was rolled back whole\", so running it again from the start is safe. Anything else, a syntax error or a broken constraint, would fail the same way every time, and retrying it only hides it."
    },
    {
      "code": "\ndef bump(conn):\n    with conn.transaction():\n        price = conn.execute(\"SELECT price_cents FROM products WHERE id = 1\").fetchone()[0]\n        time.sleep(0.001)  # the application decides; others get in meanwhile\n        conn.execute(\"UPDATE products SET price_cents = %s WHERE id = 1\", (price + 1,))\n\n",
      "note": "**The whole transaction is one function.** `conn.transaction()` sends `BEGIN`, and `COMMIT` when the block ends, or `ROLLBACK` if anything inside raised. The read and the write are both inside, so a retry repeats the read too and works from the new price, which is what makes the retry correct rather than a second lost update."
    },
    {
      "code": "\ndef with_retries(conn, work, tries=10):\n    for attempt in range(1, tries + 1):\n        try:\n            work(conn)\n            return attempt\n        except RETRY:\n            time.sleep(random.uniform(0, 0.005 * 2 ** attempt))  # back off: twice as long each time\n    raise RuntimeError(f\"gave up after {tries} tries\")\n\n",
      "note": "**The loop.** Run the work; on a retryable error, wait a short random time and run it again; give up after ten tries and say so. The random wait keeps two transactions that collided from colliding again at the same instant, and its ceiling doubles with each attempt, so a transaction that keeps losing waits long enough for the other to finish."
    },
    {
      "code": "\nconn = psycopg.connect(\"dbname=market\", autocommit=True)\nconn.execute(\"SET default_transaction_isolation = 'serializable'\")\nn = int(sys.argv[1])\nattempts = [with_retries(conn, bump) for _ in range(n)]\nprint(f\"{n} bumps, {sum(attempts) - n} retries, at most {max(attempts)} tries for one\")\n",
      "note": "**Every transaction on this connection is `SERIALIZABLE`.** `autocommit=True` stops psycopg opening a transaction of its own around everything, so the only transactions are the ones `bump` asks for. The last line counts how many attempts were extra."
    }
  ]
}
```

Two copies at once, five hundred raises each, with the price read before and after. Run from
`psql market`, so that one window holds both readings:

```
market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
       22303
(1 row)

Time: 1.883 ms

market=# \! python3 ~/bump.py 500 & python3 ~/bump.py 500 & wait
500 bumps, 2 retries, at most 3 tries for one
500 bumps, 8 retries, at most 9 tries for one

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
       23303
(1 row)

Time: 0.379 ms
```

**1000 raises, and the price went from 22303 to 23303: exactly 1000 cents.** The two programs
collided 10 times between them, two retries for one and eight for the other, and one transaction
needed nine tries. Nobody saw an error, and nothing was lost.

The wait matters as much as the loop. Two copies that retry after the same short pause collide again
at the same moment, and again after that, and can use up their ten tries in step; a wait that
doubles each time, drawn at random, is what pulls them apart. That is the general lesson about
retries: **without a
growing, random wait, two transactions that collided once tend to collide again.**

## Where the loop belongs

- **Around the unit of work, not around each statement.** In a web application that is usually the
  request handler's transaction, or a function like `bump`, which the loop can call again.
- **Not around anything with a side effect outside the database.** If the transaction sends an
  e-mail or charges a card before it commits, a retry does it twice. Do those after the commit.
- **Behind a counter.** Count retries and give-ups, the way the program's last line does. A rising
  retry rate is the first sign that two parts of the application have started fighting over the
  same rows, long before anybody sees an error.

Put `market` back with `~/reset-market.sh` before lesson 15: this lesson raised a lot of prices.
