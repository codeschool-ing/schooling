---
title: Practise on a copy
version: 1
---

A major upgrade fails in ways a minor one cannot. An extension has no build for the new version. A
setting in `postgresql.conf` was renamed. The disk has room for one copy of the data and the method
you chose needs two. The application uses a function whose behaviour changed. **Every one of these is
cheap to find on a copy and expensive to find on the server everybody uses**, so a major upgrade is
always run at least once on something that is not production.

The best copy is a separate machine restored from last night's backup, because that also proves the
backup works; restoring one is the subject of db-reliability lessons 1 to 10. On your own server
there is a cheaper copy that teaches the same steps: **a second cluster beside `16/main`**, made only
for this lesson. Lesson 3 said that postgresql-common runs several clusters side by side, and this is
what that is for. `16/main` is never stopped, never upgraded and never written to in what follows.
Note when it last started, so that the end of the lesson can prove it:

```sh
psql -c "SELECT pg_postmaster_start_time();"
```

## A second cluster

```
ana@db:~$ sudo pg_createcluster 16 rehearsal --start
Creating new PostgreSQL cluster 16/rehearsal ...
/usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/rehearsal --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/16/rehearsal ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Ver Cluster   Port Status Owner    Data directory                   Log file
16  rehearsal 5433 online postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
```

`pg_createcluster` ran `initdb` for a new data directory, wrote a configuration under
`/etc/postgresql/16/rehearsal`, and **chose the next free port, 5433**, because `main` holds 5432.
Every command aimed at the rehearsal from now on carries `-p 5433`; a command without it goes to
`main`.

```
ana@db:~$ pg_lsclusters 16
Ver Cluster   Port Status Owner    Data directory                   Log file
16  main      5432 online postgres /var/lib/postgresql/16/main      /var/log/postgresql/postgresql-16-main.log
16  rehearsal 5433 online postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
```

The new cluster is empty: it has the role `postgres` and nothing else, not even a role for you. Copy
everything across in one pipe. `pg_dumpall` writes the whole of `main` as SQL — the roles first,
then every database — and `psql` on the rehearsal runs it:

```
ana@db:~$ sudo -u postgres pg_dumpall | sudo -u postgres psql -q -p 5433 >/dev/null
ERROR:  role "postgres" already exists
ana@db:~$ psql -p 5433 -c "SELECT count(*) FROM orders;" shop
  count  
---------
 1000000
(1 row)
```

The one error is expected. The dump starts by creating the role `postgres`, and the new cluster
already has one, so that single statement fails and the rest carries on. `>/dev/null` threw away the
ordinary output of the statements; an error goes to the other stream and would still have
been printed. The million orders arrived.

## Make it look like production

A rehearsal is only as good as its resemblance to the real thing, and the thing most likely to break
a major upgrade is an **extension**. Ask every database on the real server with `\dx` and give the
copy the same list. If the extensions lessons 15 and 18 created are still in your `shop`, the
copy brought them along, and the next section's refusal will name more of them than the recording
did. **The recording machine's `shop` has none**, so it gave the rehearsal two that stand for the
two kinds there are. `pg_stat_statements` ships with PostgreSQL itself, in every version. `pg_repack`, which
lesson 15 used, is a separate project, packaged once per major version as `postgresql-16-repack`:

```sh
sudo apt install -y postgresql-16-repack
```

```
ana@db:~$ psql -p 5433 shop
shop=# CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION

shop=# CREATE EXTENSION pg_repack;
CREATE EXTENSION

shop=# \dx
                                            List of installed extensions
        Name        | Version |   Schema   |                              Description                               
--------------------+---------+------------+------------------------------------------------------------------------
 pg_repack          | 1.5.0   | public     | Reorganize tables in PostgreSQL databases with minimal locks
 pg_stat_statements | 1.10    | public     | track planning and execution statistics of all SQL statements executed
 plpgsql            | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)

shop=# \q
```

Remember those two version numbers, `1.5.0` and `1.10`. The next section upgrades this cluster to
17, and each extension causes a different problem there.
