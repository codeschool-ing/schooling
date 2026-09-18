---
title: What actually decides it in production
version: 1
---

Everything so far has been about SQL. In a company, an engine is rarely chosen on SQL. It is
chosen on what happens at three in the morning, and the questions are the same four whichever
engine is in the answer.

## Where does the second copy live

A single database server is a single point of failure, so all three servers can keep a copy
somewhere else. What differs is the shape.

**PostgreSQL** ships **streaming replication**: a primary sends its write-ahead log to one or more
replicas, which replay it. Replicas are read-only and can serve reads; failover — promoting a
replica when the primary dies — is **not** built in, and is done with an external tool such as
Patroni or repmgr. That gap surprises people and it is worth knowing before an incident rather
than during one.

**MySQL and MariaDB** ship replication that is older than PostgreSQL's and shaped differently:
the primary writes a binary log of statements or row changes and replicas apply it. It has always
been easy to set up and has historically been easy to let drift, because a replica can fall behind
or diverge without anything stopping. MySQL adds Group Replication and MariaDB adds Galera, both
of which are multi-primary and both of which change what your application may assume.

**SQLite** has none of this, because there is no server to replicate from. The file is copied, or
a separate project such as Litestream ships the WAL somewhere. That is a real answer for some
deployments and it is not the same answer.

## What does a backup mean

All three servers have a logical dump — `pg_dump`, `mysqldump` — which produces SQL text and is
slow to restore but portable and readable. All three have a physical backup of the data files —
`pg_basebackup`, Percona XtraBackup — which is fast and is tied to the version and platform.

Two things are true on every engine and are worth more than the choice between them.
**Point-in-time recovery** needs the write-ahead log or binary log kept alongside the base backup,
so that recovery can roll forward to a chosen moment; without it a backup restores you to the hour
it was taken. And **a backup nobody has restored is not a backup** — it is a file with a hopeful
name. Restoring one into a scratch server on a schedule is the only test of it there is.

SQLite's backup is copying the file, which must not be done with `cp` while a writer is active.
`sqlite3 shop.db ".backup out.db"` or the backup API takes a consistent copy of a live database,
and that is the whole procedure.

## What happens on an upgrade

**PostgreSQL** changes its on-disk format between major versions, so going from 15 to 16 is
`pg_upgrade` — a step with downtime, or a logical-replication dance to avoid it. Minor versions
are a restart. The project supports each major release for five years, and there is a well-known
failure mode of running one two years past its end because the upgrade was never scheduled.

**MySQL and MariaDB** upgrade in place more often than not, with `mysql_upgrade` or its
successor fixing the system tables. Long-term support releases are supported for around five
years.

**SQLite** has kept its file format backward-compatible since 2004 and intends to keep it that way
until 2050. Upgrading is replacing a library.

## Who is on call, and where does it run

This is the question that decides it in practice.

**A managed service removes most of the above.** Amazon RDS and Aurora, Google Cloud SQL and
AlloyDB, Azure Database, and a long list of smaller providers run PostgreSQL and MySQL — MariaDB
on fewer of them, and on some that offer it the support is thinner. If the company has no database
administrator, the engine with a managed offering on the cloud you are already paying for is a
much better answer than the engine that scores better in this lesson.

**The people you have matter more than the engine.** A team that has operated MySQL for ten years
will run a MySQL system better than a PostgreSQL one they read about. That is not an argument
against ever changing; it is an argument for counting the cost of change honestly, in people
rather than in features.

**And the answer is often "none of them yet".** For a tool, a prototype, a desktop application or
a service with one process, SQLite needs no server, no backup job, no upgrade plan and nobody on
call — and the section on it says exactly when that stops being true.

## The part that does not change

Lesson 10 said: find the query with a number attached, read the plan, measure, change one thing,
measure again. Every engine in this list keeps the counters that answer the first question and
prints a plan that answers the second. **The vocabulary changes and the method does not** — which
is also the answer to the question the next section is about.
