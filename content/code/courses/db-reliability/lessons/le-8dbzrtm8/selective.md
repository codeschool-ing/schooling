---
title: Some rows, some tables
version: 1
---

A publication does not have to offer a whole database. It names tables, and since PostgreSQL 15 it can
filter their rows with a `WHERE` or list only some of their columns. Offer only the customers in
Recife, to a second database on the 17:

```
shop=# CREATE PUBLICATION recife_pub FOR TABLE customers WHERE (city = 'Recife');
CREATE PUBLICATION
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -c "CREATE DATABASE recife"
CREATE DATABASE
ana@vm:~$ pg_dump --schema-only --no-owner --no-privileges -t customers shop | psql -q -o /dev/null -h 127.0.0.1 -p 5440 -U postgres recife
recife=# CREATE SUBSCRIPTION recife_sub CONNECTION 'host=127.0.0.1 port=5432 dbname=shop user=replicator password=replica-pass-1' PUBLICATION recife_pub;
NOTICE:  created replication slot "recife_sub" on publisher
CREATE SUBSCRIPTION
recife=# SELECT city, count(*) FROM customers GROUP BY city;
  city  | count 
--------+-------
 Recife |   250
(1 row)
```

250 customers, all in Recife: a quarter of the table, the quarter the filter selects. A regional
office that should see its own customers and nobody else's, a reporting server that needs three
tables out of forty, a search system that wants the product table and no personal data: each is a
publication, and none of them needs a copy of everything.

Each subscription is also one more slot on the publisher (`recife_sub` sits beside `shop_sub`), and
each one is a pile of log waiting to happen if its subscriber stops. Lesson 13's `lagcheck.sh` reads
`pg_stat_replication`, where these appear too, under the subscription's name.
