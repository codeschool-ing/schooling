---
title: After the upgrade
version: 1
---

The upgrade finishing is not the job finishing. `pg_upgrade`'s own last lines named two things it
left undone, and two more follow from how the method works. This section does them on
`17/rehearsal`, then takes down everything the lesson built.

## Statistics

`pg_upgrade` carries tables, rows and indexes, and **not the planner's statistics** — the sample of
each column that lesson 16 read in `pg_stats`. A new cluster with no statistics plans every query on
guesses, and the first hour after an upgrade is when slow plans appear, on a server that has just
become the one everybody uses.

`pg_upgradecluster` already dealt with it: the `vacuumdb` lines at the end of its output were its
analyze step, running `vacuumdb --all --analyze-in-stages`. The tables say when they were analysed:

```
ana@db:~$ psql -p 5433 shop
shop=# SELECT relname, last_analyze FROM pg_stat_user_tables ORDER BY relname;
  relname  |         last_analyze          
-----------+-------------------------------
 customers | 2026-10-10 16:41:19.983082-03
 orders    | 2026-10-10 16:41:19.861384-03
(2 rows)
```

**In stages** means three passes over every database: first with a statistics target of 1, which
gives the planner something within seconds, then 10, then the full default. A large database becomes
usable after the first pass instead of after the last. If you ran `pg_upgrade` by hand, or restored a
dump, nothing ran it for you:

```sh
vacuumdb --all --analyze-in-stages
```

## Extensions

The new version's packages bring new versions of an extension's files, but the database records
which version was **installed**, and that does not change by itself. `pg_upgrade` noticed and wrote
a script:

```
ana@db:~$ sudo find /var/log/postgresql -name update_extensions.sql -exec cat {} +
\connect shop
ALTER EXTENSION "pg_stat_statements" UPDATE;
```

```
shop=# \dx pg_stat_statements
                                          List of installed extensions
        Name        | Version | Schema |                              Description                               
--------------------+---------+--------+------------------------------------------------------------------------
 pg_stat_statements | 1.10    | public | track planning and execution statistics of all SQL statements executed
(1 row)

shop=# ALTER EXTENSION pg_stat_statements UPDATE;
ALTER EXTENSION

shop=# \dx pg_stat_statements
                                          List of installed extensions
        Name        | Version | Schema |                              Description                               
--------------------+---------+--------+------------------------------------------------------------------------
 pg_stat_statements | 1.11    | public | track planning and execution statistics of all SQL statements executed
(1 row)

shop=# \q
```

`pg_stat_statements` went from 1.10 to 1.11, the version 17 ships. Run the script, or the
`ALTER EXTENSION … UPDATE` it contains, in every database it names. Lesson 18 ended on keeping
extensions current, and this is the moment it was preparing for.

## Everything else to check

- The application. Point a test copy of it at the upgraded rehearsal and run what it does. The
  release notes of the new major version have a section on *incompatibilities*, and it is read
  against your own code before the real night, not during it.
- The configuration. `pg_upgradecluster` copied `postgresql.conf` across. A parameter that was
  removed or renamed in the new version stops the server at start, and the log names it.
- Replicas and backups. A physical standby cannot follow a primary of a different major
  version, and a base backup taken by 16 does not restore into 17. Both are rebuilt after the
  upgrade; db-reliability lessons 1 to 10 and 11 to 13 say how.

## Dropping the old cluster

Only once the new cluster has been checked does the old one go. `pg_upgrade` left a script called
`delete_old_cluster.sh`, and on Ubuntu you use `pg_dropcluster` instead, which also removes the
configuration and the log:

```
ana@db:~$ sudo pg_dropcluster 16 rehearsal
ana@db:~$ sudo du -sh /var/lib/postgresql/17/rehearsal
165M	/var/lib/postgresql/17/rehearsal
ana@db:~$ psql -p 5433 -Atc "SELECT count(*) FROM orders;" shop
1000000
```

**The data is still there after the old directory was deleted.** Each file had two names, and
`pg_dropcluster` removed one of them; the other, in `17/rehearsal`, keeps the file alive. `du` now
counts all of it under the new directory, and the orders are all present.

## Leaving the server as you found it

The rehearsal has served its purpose, and so have `17/main` and the publisher. Drop all three:

```
ana@db:~$ sudo pg_dropcluster --stop 17 rehearsal
ana@db:~$ sudo pg_dropcluster --stop 17 main
ana@db:~$ sudo pg_dropcluster --stop 16 source
ana@db:~$ pg_lsclusters -h
16 main 5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

**One cluster, `16/main`, as at the start of the lesson.** Ask it what it is:

```
ana@db:~$ psql -c "SHOW server_version;" -c "SELECT pg_postmaster_start_time();"
            server_version             
---------------------------------------
 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
(1 row)

   pg_postmaster_start_time    
-------------------------------
 2026-10-10 16:40:20.370122-03
(1 row)
```

Still 16.15, and its start time has not moved since the minor upgrade at the beginning of the
recording: nothing in between restarted it, upgraded it or wrote to it. On your server, compare it
with the time you noted in section 04; it should be the same. PostgreSQL 17's programs stay
installed, which costs some disk space and nothing else; `sudo apt remove postgresql-17` takes them
away if you prefer, and this course does not need them again.
