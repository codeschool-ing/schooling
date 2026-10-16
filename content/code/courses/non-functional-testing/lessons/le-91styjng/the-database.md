---
title: The database
version: 1
---

`Server-Timing` put nearly all of a look at a show in the database, and `top` showed the server
busy on the processors. The query is the one that counts the seats sold:

```sql
SELECT count(*) FROM bookings WHERE show_id = ?
```

A database will say how it intends to run a query before it runs it. In SQLite that is `EXPLAIN
QUERY PLAN`, and `sqlite3`, installed in lesson 1, asks it from the command line:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "EXPLAIN QUERY PLAN SELECT count(*) FROM bookings WHERE show_id = 990"
QUERY PLAN
`--SCAN bookings
```

**`SCAN bookings` means every row of the table is read**, all of the nearly three hundred thousand,
to count the ones belonging to one show, and that happens for every request. Nothing about it is
wrong in the sense a functional test can see: the count is right. It is slow in proportion to the
size of the table, and the table grows every time somebody books.

The cure for a scan that only wants a few rows is an **index**: a sorted copy of one column with a pointer to each row. With it the rows for one show are found the way a word is found in a
dictionary, without reading the rest. Create one on `show_id`, ask for the plan again, and ask for
a show:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "CREATE INDEX bookings_by_show ON bookings (show_id)"
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "EXPLAIN QUERY PLAN SELECT count(*) FROM bookings WHERE show_id = 990"
QUERY PLAN
`--SEARCH bookings USING COVERING INDEX bookings_by_show (show_id=?)
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=0.2, pay;dur=0.0, total;dur=0.5
```

The plan now says `SEARCH bookings USING COVERING INDEX bookings_by_show (show_id=?)`. `SEARCH`
means it goes straight to the rows it wants; `COVERING` means the index alone holds everything the
query needs, so the table itself is not read at all. The database time of one request fell from
10.2 ms to 0.2 ms.

## The same load, after

One request is a hint. The claim that matters is the one under load, so run the same eight
workers for the same twelve seconds:

```
ana@nft:~/boxoffice$ python3 measure.py 8 12 | head -4
8 workers, 13.0 s: 8532 requests, 656.4 per second
status: 200 x8532
ms          count    mean  median     p90     p95     p99     max
all          8532    11.4     8.6    13.6    15.7    23.7  1047.2
```

| | before | after |
|---|---|---|
| requests per second | 183.5 | 656.4 |
| median | 41.4 ms | 8.6 ms |
| p95 | 74.2 ms | 15.7 ms |
| p99 | 92.5 ms | 23.7 ms |

**About three and a half times the throughput, and a p95 nearly five times lower**, from one line of
SQL. That is the usual size of a missing index, and why it is the first thing to look for when the
database dominates the time. Every database has its own form of the plan: `EXPLAIN` in MySQL,
`EXPLAIN ANALYZE` in PostgreSQL, which also runs the query and reports what it really did.

One number in the new run does not fit: the maximum, 1047.2 ms, more than forty times the p99. One
request waited about a second, and the database cannot have caused it, since every query now takes
a fraction of a millisecond. "Network and infrastructure" finds where that second went.

An index is not free. It takes disk space, and every booking now writes the row and the index
entry. **On a table read far more often than it is written, like this one, the trade is worth it.** On a table written constantly and rarely read, it can go the other way,
and a load test of the writes is how you find out. In a real project the index would go into the
schema, where every new database gets it. Here it lives only in your copy of the file, and
`python3 seed.py` builds the database again without it, which is how you get the slow version
back.
