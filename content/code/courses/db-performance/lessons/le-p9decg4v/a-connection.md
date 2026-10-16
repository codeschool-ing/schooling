---
title: What one connection costs the server
version: 1
---

An application opens a connection to the database the way a browser opens a page: without a
second thought. The belief behind that is that **a connection is cheap, a socket and a few bytes**,
and that a database that refuses connections should be given more. In PostgreSQL a connection is
neither: every one is **a whole operating-system process**, with memory of its own and a share of
the processors, and the limit on how many there can be is there for a reason.

## One process per connection

Ask the operating system which processes belong to the `postgres` user, with the memory each one
holds:

```
ana@vm:~$ ps -u postgres -o pid,rss,cmd
    PID   RSS CMD
   5909 32856 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
   5910 132468 postgres: 16/main: checkpointer 
   5911 16132 postgres: 16/main: background writer 
   5913 10380 postgres: 16/main: walwriter 
   5914  9040 postgres: 16/main: autovacuum launcher 
   5915  8188 postgres: 16/main: logical replication launcher 
```

Six processes, and none of them is a client. The first is the **postmaster**, the one that listens
for connections; the others are the server's own workers — the checkpointer and the background
writer putting pages on disk, the WAL writer, the launchers for autovacuum and for logical
replication. `RSS` is the resident memory in kilobytes, and it is misleading on its own, which is the
next paragraph's subject.

Now open three `psql` sessions on `market` in three terminals, leave them at the prompt, and ask
again:

```
ana@vm:~$ ps -u postgres -o pid,rss,cmd
    PID   RSS CMD
   5909 32856 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
   5910 132660 postgres: 16/main: checkpointer 
   5911 16132 postgres: 16/main: background writer 
   5913 10380 postgres: 16/main: walwriter 
   5914  9040 postgres: 16/main: autovacuum launcher 
   5915  8188 postgres: 16/main: logical replication launcher 
   6063 13820 postgres: 16/main: ana market [local] idle
   6069 13808 postgres: 16/main: ana market [local] idle
   6070 13812 postgres: 16/main: ana market [local] idle
```

**Three new processes**, one per session, each named after its user, its database, where it
connected from and what it is doing: `ana market [local] idle`. When a client connects, the
postmaster starts a process for it, and that process serves that client and no other until it
disconnects. A thousand clients are a thousand processes.

## What each one holds

`RSS` says each new process holds about 13 MB, which would make a thousand connections thirteen
gigabytes. That number counts pages the process **shares** with the others, chiefly the server's
shared buffers, so adding the column up counts the same memory many times. The operating system
keeps the parts apart in `/proc`:

```
ana@vm:~$ grep -E "^(VmRSS|RssAnon|RssShmem)" /proc/$(pgrep -f "ana market \[local\] idle" | head -1)/status
VmRSS:	   13820 kB
RssAnon:	    3244 kB
RssShmem:	    3864 kB
```

`RssAnon` is memory this process has to itself: **3244 kB** for a session that has done nothing.
`RssShmem` is the shared memory it has touched so far, which is not its own. So an idle connection
costs a few megabytes, and a busy one costs more: every sort or hash it runs may take up to
`work_mem`, 4 MB by default, per operation, and a single query can have several. `db-administration`
lesson 6 is the arithmetic of that setting; here the point is that it is **per connection, per
operation**, so its total grows with the number of connections doing work at once.

Memory is not the only cost. Starting a process for each new connection takes a fork, a login and
a few milliseconds before the first query, which is why `pgbench` reports the initial connection
time separately. And every process takes its turn on the processors, which is the part the next
section measures.

## The limit, and the error at it

The server has a hard ceiling on processes for clients:

```
market=# SHOW max_connections;
 max_connections 
-----------------
 100
(1 row)

Time: 0.526 ms

market=# SHOW superuser_reserved_connections;
 superuser_reserved_connections 
--------------------------------
 3
(1 row)

Time: 0.474 ms

market=# SELECT count(*) FROM pg_stat_activity;
 count 
-------
     9
(1 row)

Time: 2.444 ms
```

**100 connections**, of which **3 are kept for superusers**, so that an administrator can still get
in when ordinary clients have taken the rest. The nine in `pg_stat_activity` are the three idle
sessions, this one and the server's own background processes. `db-administration` lesson 10 is where
the setting itself lives: what changing it requires and what it costs at start-up.

Ask for more than that, with `pgbench` opening 110 clients at once:

```
ana@vm:~/workload$ pgbench -n -c 110 -j 4 -T 10 -f customer-orders.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 51
```

`FATAL: sorry, too many clients already`. `pgbench` failed while it was still opening them, and gave
up the whole run. An application at that moment fails differently: its requests
start getting errors, a retry adds another attempt, and the people refreshing the page add more.
The reflex is to raise `max_connections` to 500, and the next section measures why that buys
nothing: past a few clients the server does not do more work, it only queues it in more places.
