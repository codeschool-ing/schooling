---
title: A partition that never stops growing
version: 1
---

The method of the last section has a trap in its second step. "Page views of a customer, newest
first" makes `customer` the partition key and `viewed_at` the clustering column, and the table works
on the first day and the hundredth. **But the partition has no end.** Every view adds a row to it,
nothing ever removes one, and a partition lives whole on the nodes that own its token. A customer
who has used the shop for five years is one ever-larger partition on the same few nodes.

A big partition costs in several places at once. A read that wants the newest twenty rows of a huge
partition still has to find them among millions. Compaction, lesson 18's subject, rewrites the
whole partition every time it touches it, and repair, lesson 19's, compares it as one unit. And the
nodes that own it carry the load while their neighbours sit idle. The usual guidance from the
Cassandra community is to keep partitions **below about 100 MB and, more importantly, bounded**: a
partition whose size depends on how long a customer stays is a problem scheduled for a date.

## Ninety days of one customer, two ways

To see the size, generate ninety days of Ana's page views, one every five minutes. Save this as
`views.py` and run it on the VM, which has Python 3:

```python
import csv, datetime

start = datetime.datetime(2026, 1, 1, tzinfo=datetime.timezone.utc)
pages = ["/", "/product/KB-101", "/product/MS-204", "/product/MN-330", "/basket"]

with open("views.csv", "w", newline="") as f:
    out = csv.writer(f)
    for i in range(90 * 24 * 12):  # one view every five minutes for 90 days
        t = start + datetime.timedelta(minutes=5 * i)
        out.writerow(["ana@example.com", t.strftime("%Y-%m"),
                      t.strftime("%Y-%m-%d %H:%M:%S+0000"), pages[i % len(pages)]])
```

Each line carries the month as well, `2026-01`, because the second table below needs it in its
key; the first stores it as an ordinary column. Then two tables that differ only in the partition
key, and one file loaded into both with `cqlsh`'s `COPY`:

```
ana@vm:~$ python3 views.py
ana@vm:~$ wc -l views.csv
25920 views.csv
ana@vm:~$ head -3 views.csv
ana@example.com,2026-01,2026-01-01 00:00:00+0000,/
ana@example.com,2026-01,2026-01-01 00:05:00+0000,/product/KB-101
ana@example.com,2026-01,2026-01-01 00:10:00+0000,/product/MS-204
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.views_by_customer (customer text, month text, viewed_at timestamp, page text, PRIMARY KEY (customer, viewed_at));
cqlsh> CREATE TABLE shop.views_by_customer_month (customer text, month text, viewed_at timestamp, page text, PRIMARY KEY ((customer, month), viewed_at));
cqlsh> exit
ana@vm:~$ docker exec -i c1 cqlsh -e "COPY shop.views_by_customer (customer, month, viewed_at, page) FROM STDIN" < views.csv | tail -1
25920 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 1.290 seconds (0 skipped).
ana@vm:~$ docker exec -i c1 cqlsh -e "COPY shop.views_by_customer_month (customer, month, viewed_at, page) FROM STDIN" < views.csv | tail -1
25920 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 1.353 seconds (0 skipped).
```

`views_by_customer` has one partition per customer. **`views_by_customer_month` has one per customer
per month**, because its partition key is the pair `(customer, month)`: the inner parentheses in
`PRIMARY KEY ((customer, month), viewed_at)` are what make both columns the partition key. This is
**bucketing**: a piece of time goes into the partition key, so that a partition stops growing when
its period ends.

## What the nodes measured

`nodetool flush` writes what is in memory to disk, because the partition sizes below are measured
on the files. Then where each partition lives, and what each node holds:

```
ana@vm:~$ for n in c1 c2 c3; do docker exec $n nodetool flush shop; done
ana@vm:~$ docker exec c1 nodetool getendpoints shop views_by_customer ana@example.com
172.18.0.3
ana@vm:~$ for m in 2026-01 2026-02 2026-03; do docker exec c1 nodetool getendpoints shop views_by_customer_month ana@example.com:$m; done
172.18.0.4
172.18.0.2
172.18.0.3
ana@vm:~$ for n in c1 c2 c3; do echo "== $n"; docker exec $n nodetool tablestats shop.views_by_customer shop.views_by_customer_month | grep -E "Table:|Number of partitions|partition maximum bytes"; done
== c1
		Table: views_by_customer
		Number of partitions (estimate): 0
		Compacted partition maximum bytes: 0
		Table: views_by_customer_month
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 263210
== c2
		Table: views_by_customer
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 1131752
		Table: views_by_customer_month
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 263210
== c3
		Table: views_by_customer
		Number of partitions (estimate): 0
		Compacted partition maximum bytes: 0
		Table: views_by_customer_month
		Number of partitions (estimate): 1
		Compacted partition maximum bytes: 263210
```

`Compacted partition maximum bytes` is the largest partition the node has written to disk, rounded
up to one of a fixed set of steps, so read it as a size class rather than an exact count. The
picture is plain:

| table | partitions for 90 days | largest partition | where |
| --- | --- | --- | --- |
| `views_by_customer` | 1 | 1131752 bytes, about 1.1 MB | all on `c2`; `c1` and `c3` hold nothing |
| `views_by_customer_month` | 3 | 263210 bytes, about 0.26 MB each | one month on each node |

**The unbucketed table put all of Ana's history on one node**, and it grows by about 1.1 MB every
ninety days, forever. The bucketed one spread the same rows over the three nodes, and each partition
stopped growing on the last day of its month. Ninety days is small; the arithmetic is the point. At
this rate one customer passes 40 MB in about a decade, and a busy sensor writing every second
instead of every five minutes would pass it in under a month.

## What bucketing costs

A query for "Ana's views, newest first" now names a month, so the application asks for the current
month and, if it needs more rows, the month before, one partition at a time. That is a loop in the
application instead of one query, and it is the usual price. Choose the bucket from the data rate:
a month for a customer's page views, a day or an hour for a sensor, whatever keeps one partition
well below the guidance while still answering the common query from one or two partitions.
