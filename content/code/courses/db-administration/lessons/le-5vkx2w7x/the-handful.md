---
title: The handful worth touching
version: 1
---

There are 364 parameters, and the wrong picture of configuring a server is going through them,
setting each to something better than its default. **About a dozen decide how a server behaves
under real work; the rest are right as they ship**, or matter only to somebody with a specific
problem who will know the parameter's name before opening the file. Knowing which dozen, and
which few must never be touched, is most of the skill.

## The ones worth touching

| parameter | default | what it decides | lesson |
|---|---|---|---|
| `listen_addresses` | `localhost` | which network addresses the server accepts connections on | this one, below |
| `max_connections` | `100` | how many sessions at once, each a process | 10 |
| `shared_buffers` | `128MB` | the server's own cache of table and index pages | 6 |
| `work_mem` | `4MB` | memory for one sort or hash before it spills to disk | 6 |
| `maintenance_work_mem` | `64MB` | memory for `CREATE INDEX` and `VACUUM` | 6 |
| `effective_cache_size` | `4GB` | how much cache the planner may assume exists; allocates nothing | 6 |
| `max_wal_size` | `1GB` | how much write-ahead log builds up before a checkpoint is forced | 7, 8 |
| `checkpoint_timeout` | `5min` | the longest time between checkpoints | 8 |
| `log_min_duration_statement` and the other `log_` settings | off | what reaches the log | 19 |
| the `autovacuum_` settings | on, with thresholds | when dead rows are cleaned up | 14 |
| `shared_preload_libraries` | empty | extensions loaded at start, such as `pg_stat_statements` | 18 |
| `random_page_cost` | `4` | what the planner thinks a random read costs; lower on SSDs | db-performance |

Four of these are `postmaster` parameters, which is the practical reason to decide them early:
`listen_addresses`, `max_connections`, `shared_buffers` and `shared_preload_libraries` need a
restart, and so does every later change to them.

## The ones never to relax

A few parameters trade safety for speed, and their defaults are the safe side. **`fsync = off`
stops the server making sure data has reached the disk**, and a power cut then corrupts the
cluster, not just the last few transactions. `full_page_writes = off` opens the same hole in a
different place. Both appear in advice found online about making PostgreSQL faster, and lesson 8
shows what each one protects. `synchronous_commit` is the one of the family that can be relaxed
knowingly, for data whose last second may be lost, and lesson 8 measures that too.
`autovacuum = off` belongs on the same list for a slower reason: nothing breaks today, and the
tables grow without limit until lesson 14's emergency arrives.

## listen_addresses: the door before pg_hba.conf

The previous section's file decides who may connect. **Before any of it applies, the server has
to be listening on the address the client is calling**, and by default it listens only on the
machine's loopback:

```
ana@db:~$ psql
ana=# SHOW listen_addresses;
 listen_addresses 
------------------
 localhost
(1 row)

ana=# \q
ana@db:~$ ss -ltn 'sport = 5432'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      200        127.0.0.1:5432      0.0.0.0:*          
ana@db:~$ psql -h 127.0.0.2
psql: error: connection to server at "127.0.0.2", port 5432 failed: Connection refused
	Is the server running on that host and accepting TCP/IP connections?
```

`ss -ltn` lists the sockets listening for TCP, and the filter keeps port 5432: one, on
`127.0.0.1`. Your virtual machine shows a second line for `[::1]:5432`, IPv6's loopback, which the
recording machine did not have. `127.0.0.2` stands in for an address the server is not
listening on. It belongs to this machine, so the kernel answered `Connection refused` itself and
PostgreSQL never heard of the attempt. An application on another
computer gets the same answer.

`'*'` means every address the machine has. It is a `postmaster` parameter, so it needs a restart:

```
ana@db:~$ echo "listen_addresses = '*'" | sudo tee /etc/postgresql/16/main/conf.d/60-listen.conf
listen_addresses = '*'
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ ss -ltn 'sport = 5432'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      200          0.0.0.0:5432      0.0.0.0:*          
ana@db:~$ psql -h 127.0.0.2
Password for user ana: 
psql: error: connection to server at "127.0.0.2", port 5432 failed: fe_sendauth: no password supplied
```

`0.0.0.0` is every IPv4 address. The same connection now reaches the server and gets as far as
the password question, which is `pg_hba.conf`'s line 125 at work: the connection left this machine
from `127.0.0.1`, and **the file matches the address the client came from, not the one it
called**. On a real network the two are different machines and the difference is obvious.

So opening a server to an application takes **two changes, and missing either one fails
differently**: `listen_addresses`, or the client gets `Connection refused`; a `host` line for the
client's address, or it gets `no pg_hba.conf entry`. A firewall on the machine, such as Ubuntu's
`ufw`, is a third door with the same symptom as the first. Name the addresses the server should
listen on, where you can, rather than `'*'`, and open the firewall only to the machines that need
it.

## Back to where lesson 4 left you

Everything this lesson changed is undone now, so that lesson 6 starts from the same server you
started this one with. The two files in `conf.d` go, and a restart takes `shared_buffers` and
`listen_addresses` back:

```
ana@db:~$ sudo rm /etc/postgresql/16/main/conf.d/50-course.conf /etc/postgresql/16/main/conf.d/60-listen.conf
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ ls -l /etc/postgresql/16/main/conf.d
total 0
ana@db:~$ psql
ana=# SELECT name, setting, unit, source
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'work_mem', 'listen_addresses',
ana(#                 'log_min_duration_statement')
ana-#     OR pending_restart;
            name            |  setting  | unit |       source       
----------------------------+-----------+------+--------------------
 listen_addresses           | localhost |      | default
 log_min_duration_statement | -1        | ms   | default
 shared_buffers             | 16384     | 8kB  | configuration file
 work_mem                   | 4096      | kB   | default
(4 rows)

ana=# \q
```

**`conf.d` is empty, `postgresql.auto.conf` holds only its two comments, line 125 of
`pg_hba.conf` is as the installer wrote it, and nothing is pending.** `shared_buffers` is back to
the package's 128 MB from line 130 of the main file, and the rest are defaults again. If your
server shows anything else here, the query names the parameter, and `source` says which layer
still holds it.
