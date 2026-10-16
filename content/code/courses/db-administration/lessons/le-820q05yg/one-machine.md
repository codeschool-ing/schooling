---
title: The same machine under four names
version: 1
---

It is easy to think that moving from one engine to another means learning a new trade. The products
look nothing alike: SQL Server has a graphical studio, Oracle has a vocabulary all of its own, MySQL
and PostgreSQL are configured with text files. Underneath, **every relational server is built from
the same six parts**, and the job of looking after one is the job of looking after those six.

| part | what it is | PostgreSQL | MySQL (InnoDB) | SQL Server | Oracle |
|---|---|---|---|---|---|
| the server | the program that owns the files | `postgres`, one process per connection | `mysqld`, one thread per connection | `sqlservr`, threads | a set of background processes |
| the data files | where the rows are, in pages | the data directory, 8 kB pages | the data directory, 16 kB pages | `.mdf` and `.ndf` files, 8 kB pages | datafiles in tablespaces, 8 kB blocks by default |
| the change log | every change, written before the data | write-ahead log, `pg_wal` | redo log | transaction log, `.ldf` | online redo logs |
| the cache | pages kept in memory | shared buffers | buffer pool | buffer pool | buffer cache, part of the SGA |
| the error log | what the server says about itself | `/var/log/postgresql` on Ubuntu | `error.log` | `ERRORLOG` | the alert log |
| who may do what | accounts and privileges | roles | users, and roles since 8.0 | logins at the server, users in each database | users, which are also schemas, and roles |

Read the table by rows, not by columns. **The change log** is the clearest case: all four write a
change to a sequential log first and to the data files later, because a sequential write is fast and
a crash can be repaired by replaying it. Lesson 7 explains that idea for PostgreSQL, and every word in
it applies to InnoDB's redo log and to SQL Server's transaction log. The names differ; the
reasoning, the failure modes and the settings that trade safety for speed are the same.

Two differences are real and worth carrying around. **PostgreSQL starts a process for each
connection** where the others start a thread, which is why lesson 10 says what it does about the
maximum number of connections, and why the advice for MySQL is not the same number. And **MySQL
writes a second log**, the binary log, for replication and recovery, beside InnoDB's redo log; the
other three use their change log for both.

Everything else in this course — what a configuration parameter is, why a table bloats, what a
statistic is for, how a schema changes without an outage — has a counterpart in each of the four.
The course teaches it on PostgreSQL and says where another engine is famously different.
