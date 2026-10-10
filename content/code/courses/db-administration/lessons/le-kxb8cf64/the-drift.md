---
title: The drift
version: 1
---

Two servers built from the same instructions are identical on the day they are built, and on no
day after it. **Drift** is the distance between them, and it grows one reasonable change at a time:
a slow night fixed with `ALTER SYSTEM`, a file edited on one machine with the other left for
tomorrow, a cluster made again from a different shell. Each change was right when somebody made
it. None of them was written down anywhere except on the server it changed.

The common belief is that the configuration files are the record, so comparing two servers means
comparing their files. **They are one of several places a value comes from.** Lesson 5 named them:
`postgresql.conf`, the files in `conf.d`, and `postgresql.auto.conf`, where `ALTER SYSTEM` writes.
There is one more that lives in no file at all: a setting attached to a database or a role, kept in
the catalogue. Diffing files misses it.

What every one of those places has in common is that the running server knows the result. So ask
the server, with a query you keep in a file:

```sql
-- settings.sql: every parameter this server was told, and what it was told
SELECT name, current_setting(name) AS value
FROM pg_settings
WHERE source NOT IN ('default', 'override', 'client')
  AND name NOT IN ('cluster_name', 'port', 'external_pid_file')
ORDER BY name;
```

The `WHERE` leaves out three kinds of noise. `default` is a parameter nobody set. `override` is
what `pg_ctlcluster` passes on the command line — the paths to the data directory and the
configuration files — and `client` is what `psql` sets for its own connection. The three names
excluded at the end are the ones that **must** differ between two clusters, so a difference there
is not drift. `current_setting(name)` prints a value with its unit, `64MB` rather than `65536`.

## A second server to compare with

Your machine has one cluster. A second one beside it, made with `pg_createcluster`, stands for the
second server; lesson 20 makes one the same way to rehearse an upgrade on.

```
ana@db:~$ sudo pg_createcluster --start 16 staging >/dev/null
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  staging 5433 online postgres /var/lib/postgresql/16/staging /var/log/postgresql/postgresql-16-staging.log
```

Then make `main` drift the way a server does. One change is an incident fix that stayed; the other
is tuning somebody did for the `shop` database and told nobody about:

```
shop=# ALTER SYSTEM SET work_mem = '64MB';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# ALTER DATABASE shop SET random_page_cost = 1.1;
ALTER DATABASE
```

## The comparison

Run the query against both and compare what comes out. `-XAt -F ' = '` makes `psql` print bare
`name = value` lines with no header and no `.psqlrc`, which is what `diff` wants. The staging
cluster has no role called `ana`, so that side runs as `postgres`:

```
ana@db:~$ psql -XAt -F ' = ' -f settings.sql > main.txt
ana@db:~$ sudo -u postgres psql -p 5433 -XAt -F ' = ' < settings.sql > staging.txt
ana@db:~$ diff main.txt staging.txt
5,8c5,8
< lc_messages = C.UTF-8
< lc_monetary = C.UTF-8
< lc_numeric = C.UTF-8
< lc_time = C.UTF-8
---
> lc_messages = C
> lc_monetary = C
> lc_numeric = C
> lc_time = C
19d18
< work_mem = 64MB
```

A line starting `<` is in `main.txt` only, and `>` is in `staging.txt` only. `work_mem = 64MB` is
the change you just made. **The four locale lines are drift nobody typed.** `pg_createcluster`
takes the cluster's locale from the environment of the command that runs it, and the two clusters
were made by different commands in different environments: `main` by the package's installer,
`staging` by `sudo` from your shell. Every database created in `staging` inherits `C` as well, so
its text sorts by byte rather than by the rules of a language. Of the two differences, this is the
one to worry about, because nobody will ever remember causing it.

**One change is missing.** `random_page_cost` is not in the diff, because `psql -f settings.sql`
connected to the database `ana`, and a setting attached to `shop` applies only to connections to
`shop`. `pg_settings` says where each value came from, and `\drds` lists the settings attached to
databases and roles:

```
shop=# SELECT name, setting, unit, sourcefile, sourceline FROM pg_settings WHERE name = 'work_mem';
   name   | setting | unit |                    sourcefile                    | sourceline 
----------+---------+------+--------------------------------------------------+------------
 work_mem | 65536   | kB   | /var/lib/postgresql/16/main/postgresql.auto.conf |          3
(1 row)

shop=# \drds
            List of settings
 Role | Database |       Settings       
------+----------+----------------------
      | shop     | random_page_cost=1.1
(1 row)
```

**`sourcefile` and `sourceline` turn a difference into an address.** The value is on line 3 of
`postgresql.auto.conf`, inside the data directory, which is not where anybody looks for a
configuration file on Ubuntu. A comparison worth trusting runs `settings.sql` once per database
and adds `\drds`, because the catalogue is part of the configuration too.

@@FIGURE@@

## Putting it back

Undo both changes and remove the second cluster. The rest of the course expects `main` as lesson
5 left it, and only one cluster on the machine:

```
shop=# ALTER SYSTEM RESET work_mem;
ALTER SYSTEM

shop=# ALTER DATABASE shop RESET random_page_cost;
ALTER DATABASE

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Then, back in the shell:

```
ana@db:~$ sudo pg_dropcluster --stop 16 staging
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```
