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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 186\" role=\"img\" aria-label=\"Five places a running value comes from, left to right in the order the server applies them, so a later one wins: postgresql.conf, which Ubuntu's package made and you leave alone; conf.d/50-shop.conf, your settings in one file, kept in the repository; postgresql.auto.conf, where ALTER SYSTEM writes; ALTER DATABASE or ALTER ROLE with SET, kept in the catalogue and in no file; and SET in one connection, gone when it closes. The third and fourth exist on the server only.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><line x1=\"8\" y1=\"26\" x2=\"750\" y2=\"26\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"260\" y=\"16\" width=\"260\" height=\"20\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--ink)\" stroke-width=\"0\"></rect><text x=\"390\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">read in this order, and a later value wins</text><rect x=\"8\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"79.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">postgresql.conf</text><text x=\"79.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ubuntu's, left alone</text><rect x=\"159\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">conf.d/50-shop.conf</text><text x=\"230.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your settings, one file</text><rect x=\"310\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"381.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">postgresql.auto.conf</text><text x=\"381.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ALTER SYSTEM's file</text><rect x=\"461\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ALTER DATABASE</text><text x=\"532.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ALTER ROLE … SET</text><text x=\"532.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">in the catalogue, no file</text><rect x=\"612\" y=\"48\" width=\"142\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"683.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SET</text><text x=\"683.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one connection</text><rect x=\"8\" y=\"144\" width=\"142\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"79.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">made by the package</text><rect x=\"159\" y=\"144\" width=\"142\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">kept in the repository</text><rect x=\"310\" y=\"144\" width=\"293\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"456\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">on this server only</text><rect x=\"612\" y=\"144\" width=\"142\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"683.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">gone when it closes</text></svg>", "caption": "Where a running value comes from, in the order the server applies them. Only the second is in the repository, and the two after it override it."}
```

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
