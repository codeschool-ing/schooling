---
title: Two standbys, and a quorum of one
version: 1
---

The way out of the stall is not to wait for less, but to have more to wait for. Build a second
standby the same way as the first, on port 5435, with the name `standby2` and a slot of its own,
start both, and tell the primary that **any one** of the two is enough:

```
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby2' -D /var/lib/postgresql/16/standby2 -R -C -S standby2 -X stream -c fast
ana@vm:~$ sudo pg_ctlcluster 16 standby2 start
ana@vm:~$ sudo pg_ctlcluster 16 standby start
shop=# ALTER SYSTEM SET synchronous_standby_names = 'ANY 1 (standby1, standby2)';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1;
 application_name | sync_state 
------------------+------------
 standby1         | quorum
 standby2         | quorum
(2 rows)
```

`sync_state: quorum` on both. With `ANY 1 (standby1, standby2)` a commit returns as soon as either
standby has flushed it, so it is on at least two servers, and whichever standby is slower costs
nothing. Now stop `standby1` again:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ timeout 10 psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (22, 2200, now())"; echo "exit $?"
INSERT 0 1
exit 0
shop=# SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1;
 application_name | sync_state 
------------------+------------
 standby2         | quorum
(1 row)
```

The order went through at once, `exit 0`, and only `standby2` is listed. **One standby can be lost
without stopping a write**, and every confirmed commit is still on two machines. It takes three servers
to get there, which is the real price of synchronous replication: not the third of a millisecond, but the
third machine.

## The forms of the setting

| `synchronous_standby_names` | a commit waits for |
|---|---|
| empty (the default) | nobody: replication is asynchronous |
| `'standby1'` | `standby1`, and stops when it is gone |
| `'FIRST 1 (standby1, standby2)'` | the first of the list that is connected; `standby2` takes over when `standby1` is gone |
| `'ANY 1 (standby1, standby2)'` | whichever answers first |
| `'ANY 2 (s1, s2, s3)'` | any two of the three |

`FIRST` keeps an order of preference, which matters when one standby is close and the other is far:
the far one is only waited for when the close one is gone, and then every commit slows down to its
distance. `ANY` waits for the quickest, so it is the faster of the two in steady state.

## Choosing

- **Asynchronous is the right answer more often than not.** If the business agreed in lesson 8 to an
  RPO of seconds, an asynchronous standby with its lag watched (lesson 13) meets it, at no cost per
  commit, and its failure stops nothing.
- **Synchronous is for the data where "we told the customer yes and then lost it" is not acceptable**:
  payments, ledgers, anything that leaves the building after the commit. Then it needs a quorum, so
  that one standby failing is not an outage, and the standbys need to be near.
- **Per transaction is often best of all.** The setting can be `local` for the whole server and
  `remote_apply` in the one transaction that records a payment, or the other way round. The table in
  the first section is a menu, not a server-wide choice.

And whatever is chosen, a synchronous standby is still a copy of every mistake, made a little sooner.
It protects against losing a machine; it does nothing for a `DELETE` with the wrong `WHERE`, which is
what the archive is for.
