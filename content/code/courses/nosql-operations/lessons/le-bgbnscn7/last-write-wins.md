---
title: Last write wins, by the clock
version: 1
---

Cassandra has no version number for you and no primary to send writes to. When two writes to the
same cell disagree, it decides with a rule that needs no coordination at all: **every cell carries a
timestamp, and the higher timestamp wins.** The rule is simple, fast and deterministic, and its
weakness is that "higher timestamp" is not the same thing as "later".

## Every cell has a timestamp

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE products (sku text PRIMARY KEY, name text, price decimal);
cqlsh:shop> INSERT INTO products (sku, name, price) VALUES ('MS-204', 'Wireless mouse', 189.00);
cqlsh:shop> SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';

 sku    | price  | writetime(price)
--------+--------+------------------
 MS-204 | 189.00 | 1791684040589140

(1 rows)
cqlsh:shop> UPDATE products USING TIMESTAMP 1789000000000000 SET price = 179.00 WHERE sku = 'MS-204';
cqlsh:shop> SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';

 sku    | price  | writetime(price)
--------+--------+------------------
 MS-204 | 189.00 | 1791684040589140

(1 rows)
cqlsh:shop> exit
```

`WRITETIME(price)` shows the timestamp stored with the cell, in microseconds since 1970, which the
node or the client assigned when the insert arrived. Then an update arrives carrying an **older**
timestamp, given here with `USING TIMESTAMP` to stand in for a write delayed somewhere, or stamped
by a clock that is behind. It was accepted without a word, and the `SELECT` shows it lost: the
price is still 189.00, with the original timestamp. **Silently is the important word.** The client
that sent 179.00 was told its update succeeded.

## A clock that is ahead

The other direction is worse. A write stamped with a timestamp in the future beats every write that
comes after it, until real time catches up:

```
ana@vm:~$ docker exec -it cassandra cqlsh -k shop
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh:shop> UPDATE products USING TIMESTAMP 1830000000000000 SET price = 159.00 WHERE sku = 'MS-204';
cqlsh:shop> UPDATE products SET price = 199.00 WHERE sku = 'MS-204';
cqlsh:shop> SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';

 sku    | price  | writetime(price)
--------+--------+------------------
 MS-204 | 159.00 | 1830000000000000

(1 rows)
cqlsh:shop> exit
```

The first update carries a timestamp from late 2027. The second is an ordinary update, made now,
with the price the shop actually wants. **The ordinary update lost**: the price is 159.00, and every
correction made with a normal timestamp will lose the same way until the clock passes the future
one. Nothing in the answers to the two updates differed.

## Where the wrong timestamps come from

`USING TIMESTAMP` is how this lesson makes it happen on purpose. In production it happens on its
own, through **clock skew**: the drivers and the nodes assign timestamps from their own clocks, and
clocks drift. A node or an application server whose clock is two seconds behind loses every race
it takes part in by two seconds; one whose clock jumped ahead wins races it should lose. Two writes
from two clients a millisecond apart are ordered by whichever clock was faster, not by which came
first.

So last write wins is safe for data where that does not matter, and dangerous where it does:

- **safe**: a last-seen time, a profile field one person edits, a value overwritten by a newer
  reading of the same sensor;
- **dangerous**: a stock count two checkouts update, a balance, anything computed from the value
  that was there before, which is the lost update again with the clock choosing the loser.

The defences are operational and design ones. Keep every clock synchronised with NTP and alert on
drift, which lesson 20 comes back to. Avoid read-modify-write on a shared cell; write new rows
instead of overwriting one, or use a counter, or pay for a lightweight transaction where the write
truly must be conditional, as lesson 17 shows.
