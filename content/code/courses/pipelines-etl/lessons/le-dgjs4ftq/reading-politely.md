---
title: Reading somebody else's database politely
version: 1
---

The shop's database exists to take sales. **Every query a pipeline sends it is load the tills did
not ask for**, and the person who owns it will judge the pipeline by one thing: whether the tills
slowed down. Four habits keep that from happening.

## A role that can only read

The pipeline should not connect as the shop's owner. It gets a role of its own, with permission to
read and nothing else:

```
ana@vm:~/etl$ psql -q -c "CREATE ROLE etl_reader LOGIN; GRANT SELECT ON ALL TABLES IN SCHEMA public TO etl_reader"
ana@vm:~/etl$ psql -U etl_reader -c "SELECT count(*) FROM orders"
 count 
-------
 18020
(1 row)

ana@vm:~/etl$ psql -U etl_reader -c "UPDATE orders SET status = 'cancelled' WHERE order_id = 100001"
ERROR:  permission denied for table orders
```

The second command is the point. A bug in the pipeline, an `UPDATE` pasted into the wrong terminal,
a library that "helpfully" creates a table: none of them can touch the shop through this role. And
in `pg_stat_activity`, which lists every open session, the pipeline's connections now carry a name
of their own, which is how the owner of the source finds you before they find the problem.

## Somewhere else to read

A large read belongs on a **read replica**: a copy of the database that PostgreSQL keeps up to date
from the primary's write-ahead log, a second or so behind it, which takes no sales. The tills never
notice an extraction that runs there. The lab has no replica, and the course reads the primary;
in production that is a decision somebody should have to make out loud.

## A time to read

Nightly extractions run in the hours the shop is shut, and the lab's schedule from lesson 9 says
so. The online shop never closes, which is one more reason the replica is the normal answer.

## Less to read

The cheapest query is the one that reads only what changed. Every extraction in lessons 1 and 2
read a whole day or a whole week again; lesson 4 reads only the rows modified since the last run,
and lesson 5 reads the changes from the database's own log without querying the tables at all.
