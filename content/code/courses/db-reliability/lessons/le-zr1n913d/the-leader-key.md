---
title: The shop on the cluster, and the key in etcd
version: 1
---

The cluster is empty. Load the shop into the leader with lesson 1's `shop.sql`, connecting as the
`postgres` role Patroni created, with its password in `~/.pgpass`, and count the orders on `pg3`:

```
ana@vm:~$ echo '127.0.0.1:*:*:postgres:patroni-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass
ana@vm:~$ createdb -h 127.0.0.1 -p 5441 -U postgres shop
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -q -f shop.sql shop
psql:shop.sql:2: NOTICE:  table "orders" does not exist, skipping
psql:shop.sql:2: NOTICE:  table "customers" does not exist, skipping
ana@vm:~$ psql -h 127.0.0.1 -p 5443 -U postgres -XAt shop -c "SELECT count(*) FROM orders"
50000
```

Fifty thousand on a replica that nobody loaded by hand. Now look at what Patroni keeps in etcd:

```
ana@vm:~$ etcdctl get --prefix --keys-only /service/shop/
/service/shop/config

/service/shop/initialize

/service/shop/leader

/service/shop/members/pg1

/service/shop/members/pg2

/service/shop/members/pg3

/service/shop/status

ana@vm:~$ etcdctl get --print-value-only /service/shop/leader
pg1
```

`config` holds the settings every node shares, the `bootstrap.dcs` section of the file once the
cluster exists. `members/` has one entry per node, which each node rewrites on every loop with its
state and position. `status` holds the leader's last position in the log. `initialize` records which cluster this is, so that a node pointed at the wrong
etcd cannot join it. And `leader`, whose value is a name: **`pg1`**. That one string is the answer to
"which node is the primary", and the only answer every node trusts.
