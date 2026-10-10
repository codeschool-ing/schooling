---
title: Making the primary wait
version: 1
---

The replica of lesson 2 was **asynchronous**: the primary confirmed a sale to the buyer and sent
it to the replica afterwards. Section 06 of that lesson listed what that costs: a replica that
answers with the past, and confirmed sales that die with the primary.

**Synchronous replication** closes that gap. The primary does not tell the client a transaction is
committed until at least one replica confirms it has the change safely in its own log. A
confirmed sale is then on two machines, and losing one loses nothing that anybody was told
happened.

PostgreSQL decides which replicas count with one setting on the primary,
`synchronous_standby_names`. `'*'` means any one replica; a list of names, or `ANY 2 (a, b, c)`,
asks for more. It can be changed while the server runs: `ALTER SYSTEM` writes it to the server's
configuration file and `pg_reload_conf()` makes the server read it.

## What it costs, measured

`pgbench` is PostgreSQL's own load generator, and it ships in the same image. `-i` creates its four
tables, `-s 4` makes them four times the default size, and a run with four clients for ten seconds
measures transactions that each update three rows and insert one. First with the replica
asynchronous, as lesson 2 left it:

```
ana@lab:~/tickets$ docker compose exec db pgbench -U tickets -i -s 4 -q tickets
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
400000 of 400000 tuples (100%) done (elapsed 0.40 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.91 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.42 s, vacuum 0.14 s, primary keys 0.34 s).
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sync_state FROM pg_stat_replication'
 sync_state 
------------
 async
(1 row)

ana@lab:~/tickets$ docker compose exec db pgbench -U tickets -n -c 4 -T 10 tickets
pgbench (16.15 (Debian 16.15-1.pgdg13+2))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 4
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 19921
number of failed transactions: 0 (0.000%)
latency average = 2.008 ms
initial connection time = 10.582 ms
tps = 1992.400653 (without initial connection time)
```

Then the same run, after asking the primary to wait for the replica:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "ALTER SYSTEM SET synchronous_standby_names = '*'" -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sync_state FROM pg_stat_replication'
 sync_state 
------------
 sync
(1 row)

ana@lab:~/tickets$ docker compose exec db pgbench -U tickets -n -c 4 -T 10 tickets
pgbench (16.15 (Debian 16.15-1.pgdg13+2))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 4
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 14392
number of failed transactions: 0 (0.000%)
latency average = 2.778 ms
initial connection time = 11.193 ms
tps = 1439.731837 (without initial connection time)
```

`sync_state` changed from `async` to `sync`, and the same transactions went from **2.008 ms to
2.778 ms** on average, from 1992 a second to 1440. **Every commit now waits for a round trip to
the replica and a write to its disk.** Here the replica is on the same machine, behind a virtual
network bridge, so the round trip is tens of microseconds and most of the extra is the replica's
own write.

On real networks the round trip is the larger part. Between two data centres in the same city it
is around a millisecond; between São Paulo and the east coast of the United States it is well over
a hundred. A synchronous replica on another continent adds that to **every commit**, which is why
synchronous replicas usually sit close to the primary, and the far ones stay asynchronous.

## Which wait

`synchronous_commit` decides how far the primary waits, per transaction if you like:

| value | the commit returns when the change is | a crash or failover can lose it? |
|---|---|---|
| `off` | in the primary's memory | yes, a few hundred ms of commits |
| `local` | on the primary's disk | yes, if the primary is lost |
| `on` (with a synchronous replica) | on the primary's disk and in the replica's | no |
| `remote_apply` | applied on the replica, visible to reads there | no, and a replica read sees it |

`remote_apply` is the one that would have saved lesson 2's buyer from not seeing their ticket. It
also makes every commit wait for the slowest synchronous replica to finish applying, which is the
most expensive line in the table.
