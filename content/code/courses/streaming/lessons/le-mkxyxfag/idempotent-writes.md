---
title: Writes that can be repeated
version: 1
---

**A write is idempotent when doing it twice leaves the same result as doing it once.** Lesson 7
ended with a consumer that delivers every sale at least once, and so sometimes twice. If every
write it makes is idempotent, the second delivery changes nothing and the duplicate is harmless,
without anybody having to detect it.

The distinction is in the shape of the statement, not in the database:

| idempotent | not idempotent |
|---|---|
| `SET qty = 98` | `SET qty = qty - 2` |
| insert the sale **keyed by its id**, ignoring one that is there | insert the sale with a new row id each time |
| put a file at a fixed name | append a line to a file |
| `DELETE` the reservation for order 42 | decrement a count of reservations |

The left column **sets a value**; the right one **adds to the value that is there**. A stock count
kept by subtracting each sale is the most natural code anybody writes, and the most fragile
under at-least-once.

## In SQLite

The downstream store in this lesson is SQLite, which is a database in a single file, built into
Python. Python 3.12 can also run one SQL statement at a time from the shell with
`python -m sqlite3 FILE "SQL"`, which is what the transcripts below use; it prints each row as a
tuple. First, the counter that adds, with the same sale of two copies of `bk-04` applied twice:

```
ubuntu@stream:~/work$ python -m sqlite3 demo.db "CREATE TABLE sold (book TEXT PRIMARY KEY, qty INTEGER NOT NULL)"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "INSERT INTO sold VALUES ('bk-04', 0)"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "UPDATE sold SET qty = qty + 2 WHERE book = 'bk-04'"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "UPDATE sold SET qty = qty + 2 WHERE book = 'bk-04'"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "SELECT * FROM sold"
('bk-04', 4)
```

**Two deliveries of one sale of two copies, and the table says four.** Nothing in the second
statement could tell it was a repeat; it adds to whatever is there.

Now the other shape. The sales themselves are stored, **keyed by the sale's id**, and the number
sold is computed from them. `ON CONFLICT (sale) DO NOTHING` turns a second insert of the same id
into nothing at all; SQLite calls this an **upsert** when the conflict clause updates instead:

```
ubuntu@stream:~/work$ python -m sqlite3 demo.db "CREATE TABLE sales (sale TEXT PRIMARY KEY, book TEXT, qty INTEGER)"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "INSERT INTO sales VALUES ('rec-000007', 'bk-04', 2) ON CONFLICT (sale) DO NOTHING"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "INSERT INTO sales VALUES ('rec-000007', 'bk-04', 2) ON CONFLICT (sale) DO NOTHING"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "SELECT book, sum(qty) FROM sales GROUP BY book"
('bk-04', 2)
```

The second insert hits the primary key and does nothing, and **the total stays at two**. The
duplicate was harmless without anybody looking for it, because the write was shaped so that a
second copy has nowhere to go.

## The catch

Storing facts and computing totals from them is the most robust design there is, and it is not
always available. A stock count that has to be read a thousand times a second is not going to be
a `SUM` over every sale ever made; a payment provider's API that charges a card is not a table
with a primary key. **Making the write idempotent works when you control its shape**, and when you
do not, the consumer has to remember what it has already done. That is the next section, and it
turns out to be the same idea moved one step: a table keyed by the sale's id, but holding only the
ids.
