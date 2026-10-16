---
title: The publisher
version: 1
---

The log only carries enough to rebuild rows if `wal_level` says so. Its default, `replica`, is what
physical replication needs; logical decoding needs `logical`, and changing it takes a restart:

```
shop=# ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql -XAt shop -c "SHOW wal_level"
logical
```

A publication names its tables. The subscriber will connect as lesson 11's role `replicator`, which
has the right to replicate and no right to read a table, and a logical subscription starts with a
plain copy of each table's rows, so the role is given `SELECT` on exactly those two:

```
shop=# CREATE PUBLICATION shop_pub FOR TABLE customers, orders;
CREATE PUBLICATION

shop=# GRANT SELECT ON customers, orders TO replicator;
GRANT
```

Nothing has happened yet: a publication is an offer, and nothing is sent until somebody subscribes.
