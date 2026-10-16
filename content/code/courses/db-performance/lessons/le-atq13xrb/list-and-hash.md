---
title: By list and by hash
version: 1
---

Range is the kind you will use most, because time is the slice most tables age by. The other two
answer different questions, and each has one mistake that is easy to make with it.

## By list: a partition per named value

**List** partitioning gives each partition a set of values of the key. It fits a column with a few
known values that matter to how the data is kept: a country whose rows must stay in one place, a
tenant big enough to deserve its own table, a status whose rows are handled differently. On
`events`, the kinds split naturally into browsing and buying:

```
market=# CREATE TABLE events_by_kind (LIKE events_by_month) PARTITION BY LIST (kind);
CREATE TABLE
Time: 6.983 ms

market=# CREATE TABLE events_browse PARTITION OF events_by_kind FOR VALUES IN ('view', 'search');
CREATE TABLE
Time: 5.028 ms

market=# CREATE TABLE events_buy PARTITION OF events_by_kind FOR VALUES IN ('cart', 'checkout');
CREATE TABLE
Time: 4.037 ms

market=# INSERT INTO events_by_kind SELECT * FROM events;
INSERT 0 5000000
Time: 12876.632 ms (00:12.877)

market=# SELECT tableoid::regclass AS partition, kind, count(*) FROM events_by_kind GROUP BY 1, 2 ORDER BY 1, 2;
   partition   |   kind   |  count  
---------------+----------+---------
 events_browse | search   |  999127
 events_browse | view     | 3000104
 events_buy    | cart     |  500558
 events_buy    | checkout |  500211
(4 rows)

Time: 740.017 ms
```

`IN ('view', 'search')` and `IN ('cart', 'checkout')`: one partition takes four million rows and the
other one million. A list does not try to balance anything; it puts each value **where you said**.
That is the point when the reason is administrative — the buying events kept for five years and the
browsing ones for ninety days, each partition dropped on its own schedule — and a problem when
somebody expected even halves.

The mistake with a list is the value nobody listed. A new kind, `wishlist`, would be refused exactly
as the March row was in section 03, the day the application started sending it. A default
partition, section 05, catches it, and a list partition is the place where one is most often worth
having.

## By hash: rows spread by a function of the key

**Hash** partitioning gives each partition a remainder: the key is hashed, the hash divided by the
**modulus**, and the row goes to the partition whose **remainder** matches. Nobody chooses where a
given customer lands, and with a key of many values the rows spread evenly. It is for splitting a
big table into pieces of similar size when there is no slice that ages, so that each piece is
smaller to vacuum, to index and to rebuild. It is also the layout lesson 19 builds on when the
pieces go to different servers.

Four partitions by `customer_id`:

```
market=# CREATE TABLE events_by_customer (LIKE events_by_month) PARTITION BY HASH (customer_id);
CREATE TABLE
Time: 10.235 ms

market=# CREATE TABLE events_by_customer_0 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE
Time: 6.812 ms

market=# CREATE TABLE events_by_customer_1 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE
Time: 6.081 ms

market=# CREATE TABLE events_by_customer_2 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE
Time: 5.215 ms

market=# CREATE TABLE events_by_customer_3 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 3);
CREATE TABLE
Time: 5.453 ms

market=# INSERT INTO events_by_customer SELECT * FROM events;
INSERT 0 5000000
Time: 12961.050 ms (00:12.961)

market=# SELECT tableoid::regclass AS partition, count(*), count(customer_id) AS with_customer FROM events_by_customer GROUP BY 1 ORDER BY 1;
      partition       |  count  | with_customer 
----------------------+---------+---------------
 events_by_customer_0 | 2372458 |        871797
 events_by_customer_1 |  880155 |        880155
 events_by_customer_2 |  873158 |        873158
 events_by_customer_3 |  874229 |        874229
(4 rows)

Time: 505.837 ms
```

Three partitions of about 875 thousand rows, which is the even spread a hash promises. And one of
**2372458**, nearly three times the others. The `with_customer` column says why: partition 0 holds
its own 871797 customers' events **plus every event with no customer**. Three in ten events are
visitors without an account, `customer_id` is `NULL` for all of them, and every `NULL` goes to the
same partition.

That is the hash's mistake, and the general form of it is worth remembering: **a hash spreads
values, not rows.** One value that is very common, `NULL` here, or the marketplace's own seller 1
if this were `orders` by seller, lands every one of its rows in one place, however many partitions
there are. Before choosing a hash key, count the commonest values; lesson 7 showed where the
statistics already keep them.

The two tables were only for looking at. Drop them, so that `market` keeps one partitioned table,
the one lesson 18 uses:

```
market=# DROP TABLE events_by_kind, events_by_customer;
DROP TABLE
Time: 830.238 ms
```

## Choosing the key

The key decides everything else, and it cannot be changed without rebuilding the table. Three
questions settle it, in this order:

- **How do rows leave?** If old rows are removed by date, the key is the date and the kind is range,
  whatever else is true. That is the job from section 02.
- **What do most queries filter on?** Pruning only works on the key, so a key that the important
  queries never mention leaves every query reading every partition.
- **Is any one value huge?** A list puts it where you say; a hash puts it somewhere you did not
  choose, and with everything else that shares its partition.

`events` answers the first question with `at`, which is why `events_by_month` is cut by range.
PostgreSQL also lets a partition be partitioned again, a month by hash for example, and that is
occasionally right; it multiplies the partition count, and lesson 18 measures what partition counts
cost.
