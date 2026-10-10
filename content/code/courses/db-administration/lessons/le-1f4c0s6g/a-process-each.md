---
title: A process for every connection
version: 1
---

Many servers handle their clients with threads inside one process, and it is easy to assume
PostgreSQL does the same. It does not. **Every client connection gets an operating-system process
of its own**, created by the postmaster when the client connects, and that process does all of
the client's work until it disconnects. PostgreSQL calls it a **backend**.

To see it, open two more terminals on the server. In the first, connect and leave the prompt
waiting; in the second, run a query that takes a while:

```sh
psql shop
```

```sh
psql shop -c "SELECT pg_sleep(600)"
```

Then, from your original terminal, list the processes that belong to `postgres`:

```
ana@db:~$ ps -u postgres -o pid,ppid,cmd
    PID    PPID CMD
    101       1 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
    102     101 postgres: 16/main: checkpointer 
    103     101 postgres: 16/main: background writer 
    105     101 postgres: 16/main: walwriter 
    106     101 postgres: 16/main: autovacuum launcher 
    107     101 postgres: 16/main: logical replication launcher 
    202     101 postgres: 16/main: ana shop [local] idle
    215     101 postgres: 16/main: ana shop [local] SELECT
```

The workers from lesson 3 are there, and below them **one process for each terminal**. The `PPID`
column is the parent: every one of them was started by process 101, the postmaster, which does
nothing but accept connections and start processes to serve them. A backend rewrites its own name
so that `ps` can be read: the cluster, the role, the database, where the client is (`[local]` is
the socket) and what it is doing right now. One is `idle`, waiting at a prompt; the other is in
the middle of a `SELECT`.

## The same list from inside

`pg_stat_activity` is that list as the server keeps it, one row per process, and it is what you
query rather than `ps` when you need to filter or join:

```
ana@db:~$ psql shop
shop=# SELECT pid, backend_type, usename, state, left(query, 24) AS query
shop-#   FROM pg_stat_activity ORDER BY backend_type, pid;
 pid |         backend_type         | usename  | state  |          query           
-----+------------------------------+----------+--------+--------------------------
 106 | autovacuum launcher          |          |        | 
 103 | background writer            |          |        | 
 102 | checkpointer                 |          |        | 
 202 | client backend               | ana      | idle   | 
 215 | client backend               | ana      | active | SELECT pg_sleep(600)
 224 | client backend               | ana      | active | SELECT pid, backend_type
 107 | logical replication launcher | postgres |        | 
 105 | walwriter                    |          |        | 
(8 rows)
```

The `pid` is the same number `ps` printed, which is how you move between the two views. There are
three client backends now, because the session asking is one of them. **`state` is the column you
will read most**: `active` is running a statement, `idle` is connected and doing nothing, and a
third state that matters more than both has a section of its own later in this lesson. `query` is
the last statement the backend ran, or the one it is running while it is `active`; an idle
backend's is simply its most recent.

## Why a process matters

A process is a heavy thing to have per client, and every consequence in this lesson follows from
it:

- **connecting costs a process start**, plus authentication, every time. The last section measures
  it.
- **each backend has memory of its own** on top of the shared buffers: its caches of the catalogue,
  and up to `work_mem` for every sort and hash it runs, which lesson 6 multiplied out.
- **the processors are shared by all of them.** A machine with four processors runs four backends
  at once; the rest wait their turn, and the kernel spends time switching between them.

Ending one is also an operating-system act underneath. Close the two extra terminals before going
on; their backends exit with them.
