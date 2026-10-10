---
title: pg_upgrade, through pg_upgradecluster
version: 1
---

## Getting PostgreSQL 17

Ubuntu 24.04's archive stops at 16, so 17 comes from the PostgreSQL project's own apt repository,
**apt.postgresql.org**, which publishes every supported major version for every current Ubuntu.
postgresql-common carries a script that adds it, with its signing key:

```sh
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt install -y postgresql-17
```

**The recording machine could not reach that repository**, and the server in it has no network at
all. Its 17 was built from the source of the same release, 17.10, and installed into the same
places the package uses — `/usr/lib/postgresql/17` for the programs, `/usr/share/postgresql/17` for
the rest — where postgresql-common finds it exactly as it finds the package. The one visible
difference is the version string: yours carries the repository's packaging in brackets after
`17.10`, and the recording's has nothing after it.

```
ana@db:~$ pg_lsclusters 17
Ver Cluster   Port Status Owner    Data directory                   Log file
16  main      5432 online postgres /var/lib/postgresql/16/main      /var/log/postgresql/postgresql-16-main.log
16  rehearsal 5433 online postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
17  main      5434 online postgres /var/lib/postgresql/17/main      /var/log/postgresql/postgresql-17-main.log
ana@db:~$ psql --version
psql (PostgreSQL) 17.10
```

**Installing the package made a cluster.** The first time a major version is installed,
postgresql-common creates a `main` cluster for it and starts it, on the next free port — here 5434,
because the rehearsal holds 5433. `17/main` is empty, and the next section puts it to work.

The other change is quieter: `psql` now reports 17.10 even though `main` is still 16. The command
`psql` is a wrapper from postgresql-common, and for `psql` it always runs the newest version
installed, because a newer `psql` talks to older servers. Most other tools, `pg_dump` among them,
follow the version of the cluster they are pointed at, which matters in the next section.

## Why the new server cannot just start

17's own server, given the rehearsal's data directory, refuses before it touches anything:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/17/bin/postgres -D /var/lib/postgresql/16/rehearsal -c config_file=/etc/postgresql/16/rehearsal/postgresql.conf
2026-10-10 04:43:51.181 -03 [4434] FATAL:  database files are incompatible with server
2026-10-10 04:43:51.181 -03 [4434] DETAIL:  The data directory was initialized by PostgreSQL version 16, which is not compatible with this version 17.10.
```

That is the reason major upgrades are a project. The rest of this section is `pg_upgrade`, the
fastest of the three ways across.

## pg_upgrade, and the wrapper around it

`pg_upgrade` is PostgreSQL's own tool. It takes the old cluster's schema with `pg_dump`, creates it
in a fresh cluster of the new version, and then **moves the data files across without reading
them**: the format of a table's pages did not change between 16 and 17, only the catalogue that
describes them. On Ubuntu you seldom call it directly. postgresql-common's **`pg_upgradecluster`**
creates the new cluster, copies the configuration, runs `pg_upgrade` with the right paths, swaps the
ports, and runs a step afterwards that the next sections explain.

Two of its options decide everything. **`-m upgrade` chooses pg_upgrade**; without it,
`pg_upgradecluster` falls back to its default, a dump and restore, which is correct but takes as long
as the data is big. **`--link`** makes pg_upgrade hard-link the data files into the new cluster
instead of copying them, and that choice has a price the end of this section shows.

## The first run, refused

```
ana@db:~$ sudo pg_upgradecluster -m upgrade --link 16 rehearsal
Stopping old cluster...
Creating new PostgreSQL cluster 17/rehearsal ...
/usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/rehearsal --auth-local peer --auth-host scram-sha-256 --no-instructions --encoding UTF8 --lc-collate C.UTF-8 --lc-ctype C.UTF-8 --locale-provider libc
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/17/rehearsal ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default "max_connections" ... 100
selecting default "shared_buffers" ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Copying old configuration files...
Copying old start.conf...
Copying old pg_ctl.conf...
Running init phase upgrade hook scripts ...

/usr/lib/postgresql/17/bin/pg_upgrade -b /usr/lib/postgresql/16/bin -B /usr/lib/postgresql/17/bin -p 5433 -P 5435 -d /etc/postgresql/16/rehearsal -D /etc/postgresql/17/rehearsal --link
Finding the real data directory for the source cluster        ok
Finding the real data directory for the target cluster        ok
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
Checking database user is the install user                    ok
Checking database connection settings                         ok
Checking for prepared transactions                            ok
Checking for contrib/isn with bigint-passing mismatch         ok
Checking data type usage                                      ok
Checking for not-null constraint inconsistencies              ok
Creating dump of global objects                               ok
Creating dump of database schemas                             ok
Checking for presence of required libraries                   fatal

Your installation references loadable libraries that are missing from the
new installation.  You can add these libraries to the new installation,
or remove the functions using them from the old installation.  A list of
problem libraries is in the file:
    /var/lib/postgresql/17/rehearsal/pg_upgrade_output.d/20261010T044352.796/loadable_libraries.txt
Failure, exiting
pg_upgradecluster: pg_upgrade output scripts are in /var/log/postgresql/pg_upgradecluster-16-17-rehearsal.d3bZ
Error during cluster dumping, removing new cluster

Cluster is not running.
Starting old cluster again ...
```

Read it in order. The old cluster was **stopped** — a real upgrade starts its downtime on the first
line. The new cluster `17/rehearsal` was created and given the old configuration. `pg_upgrade` ran
its consistency checks, dumped the schemas, and failed on **`Checking for presence of required
libraries`**. Then `pg_upgradecluster` dropped the half-made cluster and started the old one again.

Nothing was lost, because nothing had been moved: every check runs before a single data file is
touched. The file it names, kept in the log directory, says what is missing:

```
ana@db:~$ sudo find /var/log/postgresql -name loadable_libraries.txt -exec cat {} +
could not load library "$libdir/pg_repack": ERROR:  could not access file "$libdir/pg_repack": No such file or directory
In database: shop
```

pg_repack's library exists for 16 and not for 17. A real server has two ways out. Install the
extension's build for the new version — the PostgreSQL repository has `postgresql-17-repack`, and on
a machine that can reach it, `sudo apt install postgresql-17-repack` is the fix. Or, when the
extension is not needed, drop it before upgrading. pg_repack is a tool rather than a place where data
lives, so dropping it loses nothing, and that is what the recording machine did:

```
ana@db:~$ psql -p 5433 shop
shop=# DROP EXTENSION pg_repack;
DROP EXTENSION

shop=# \q
```

**That refusal is the rehearsal paying for itself.** On `main`, on the night, it would have been the
same output with people waiting.

## The second run

```
ana@db:~$ time sudo pg_upgradecluster -m upgrade --link 16 rehearsal
Stopping old cluster...
Creating new PostgreSQL cluster 17/rehearsal ...
/usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/rehearsal --auth-local peer --auth-host scram-sha-256 --no-instructions --encoding UTF8 --lc-collate C.UTF-8 --lc-ctype C.UTF-8 --locale-provider libc
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/17/rehearsal ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default "max_connections" ... 100
selecting default "shared_buffers" ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Copying old configuration files...
Copying old start.conf...
Copying old pg_ctl.conf...
Running init phase upgrade hook scripts ...

/usr/lib/postgresql/17/bin/pg_upgrade -b /usr/lib/postgresql/16/bin -B /usr/lib/postgresql/17/bin -p 5433 -P 5435 -d /etc/postgresql/16/rehearsal -D /etc/postgresql/17/rehearsal --link
Finding the real data directory for the source cluster        ok
Finding the real data directory for the target cluster        ok
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
Checking database user is the install user                    ok
Checking database connection settings                         ok
Checking for prepared transactions                            ok
Checking for contrib/isn with bigint-passing mismatch         ok
Checking data type usage                                      ok
Checking for not-null constraint inconsistencies              ok
Creating dump of global objects                               ok
Creating dump of database schemas                             ok
Checking for presence of required libraries                   ok
Checking database user is the install user                    ok
Checking for prepared transactions                            ok
Checking for new cluster tablespace directories               ok

If pg_upgrade fails after this point, you must re-initdb the
new cluster before continuing.

Performing Upgrade
------------------
Setting locale and encoding for new cluster                   ok
Analyzing all rows in the new cluster                         ok
Freezing all rows in the new cluster                          ok
Deleting files from new pg_xact                               ok
Copying old pg_xact to new server                             ok
Setting oldest XID for new cluster                            ok
Setting next transaction ID and epoch for new cluster         ok
Deleting files from new pg_multixact/offsets                  ok
Copying old pg_multixact/offsets to new server                ok
Deleting files from new pg_multixact/members                  ok
Copying old pg_multixact/members to new server                ok
Setting next multixact ID and offset for new cluster          ok
Resetting WAL archives                                        ok
Setting frozenxid and minmxid counters in new cluster         ok
Restoring global objects in the new cluster                   ok
Restoring database schemas in the new cluster                 ok
Adding ".old" suffix to old global/pg_control                 ok

If you want to start the old cluster, you will need to remove
the ".old" suffix from /var/lib/postgresql/16/rehearsal/global/pg_control.old.
Because "link" mode was used, the old cluster cannot be safely
started once the new cluster has been started.
Linking user relation files                                   ok
Setting next OID for new cluster                              ok
Sync data directory to disk                                   ok
Creating script to delete old cluster                         ok
Checking for extension updates                                notice

Your installation contains extensions that should be updated
with the ALTER EXTENSION command.  The file
    update_extensions.sql
when executed by psql by the database superuser will update
these extensions.

Upgrade Complete
----------------
Optimizer statistics are not transferred by pg_upgrade.
Once you start the new server, consider running:
    /usr/lib/postgresql/17/bin/vacuumdb --all --analyze-in-stages
Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh
pg_upgradecluster: pg_upgrade output scripts are in /var/log/postgresql/pg_upgradecluster-16-17-rehearsal.h877
Disabling automatic startup of old cluster...
Starting upgraded cluster on port 5433...
Running finish phase upgrade hook scripts ...
vacuumdb: processing database "ana": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "postgres": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "shop": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "template1": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "ana": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "postgres": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "shop": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "template1": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "ana": Generating default (full) optimizer statistics
vacuumdb: processing database "postgres": Generating default (full) optimizer statistics
vacuumdb: processing database "shop": Generating default (full) optimizer statistics
vacuumdb: processing database "template1": Generating default (full) optimizer statistics

Success. Please check that the upgraded cluster works. If it does,
you can remove the old cluster with
    pg_dropcluster 16 rehearsal

Ver Cluster   Port Status Owner    Data directory                   Log file
16  rehearsal 5435 down   postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
Ver Cluster   Port Status Owner    Data directory                   Log file
17  rehearsal 5433 online postgres /var/lib/postgresql/17/rehearsal /var/log/postgresql/postgresql-17-rehearsal.log

real	0m8.556s
user	0m1.097s
sys	0m1.060s
```

The stages are worth knowing, because a real run takes longer and you will watch it:

- `Performing Consistency Checks` is the part that failed before, and it passed.
- `If pg_upgrade fails after this point, you must re-initdb the new cluster` is the line where
  checking ends and doing begins.
- `Restoring database schemas` builds the catalogue of `17/rehearsal` from the dump of 16's.
- `Adding ".old" suffix to old global/pg_control` disables the old cluster on purpose, for a
  reason the next part shows.
- `Linking user relation files` is the data, all of it, in one line.
- `Checking for extension updates` and `Optimizer statistics are not transferred` are two jobs
  left for you, and the section after next does them.

After `pg_upgrade`, `pg_upgradecluster` marked the old cluster to stay down at boot, **gave the new
cluster the old port**, started it, and ran its analyze step: the `vacuumdb` lines.

```
ana@db:~$ pg_lsclusters
Ver Cluster   Port Status Owner    Data directory                   Log file
16  main      5432 online postgres /var/lib/postgresql/16/main      /var/log/postgresql/postgresql-16-main.log
16  rehearsal 5435 down   postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
17  main      5434 online postgres /var/lib/postgresql/17/main      /var/log/postgresql/postgresql-17-main.log
17  rehearsal 5433 online postgres /var/lib/postgresql/17/rehearsal /var/log/postgresql/postgresql-17-rehearsal.log
```

`17/rehearsal` answers on 5433, where the rehearsal always was, so anything that connected to the
old cluster now reaches the new one without a change. The old cluster moved to 5435 and is down.

## What --link did

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two ways pg_upgrade moves a table file. Without --link, 16/rehearsal and 17/rehearsal each hold their own copy of base/16386/16393: twice the disk and the time to copy it, and 16 can still be started, so the old cluster is the way back. With --link, both directory entries point at one file with a link count of 2: no extra disk and seconds at any size, but 17 writes into the shared file, so the way back is a backup.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">without --link: copied</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">with --link: linked</text><line x1=\"360\" y1=\"8\" x2=\"360\" y2=\"262\" stroke=\"var(--scan)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></line><rect x=\"30\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">16/rehearsal/</text><text x=\"100\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><rect x=\"190\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">17/rehearsal/</text><text x=\"260\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><line x1=\"100\" y1=\"80\" x2=\"100\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"260\" y1=\"80\" x2=\"260\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"30\" y=\"130\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"100.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the orders table's data</text><text x=\"100.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one copy each</text><rect x=\"190\" y=\"130\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"260.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the orders table's data</text><text x=\"260.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one copy each</text><text x=\"180\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">twice the disk, and time to copy it all</text><text x=\"180\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 can still be started:</text><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the old cluster is the way back</text><rect x=\"390\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">16/rehearsal/</text><text x=\"460\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><rect x=\"550\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">17/rehearsal/</text><text x=\"620\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><line x1=\"460\" y1=\"80\" x2=\"520\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"620\" y1=\"80\" x2=\"560\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"450\" y=\"130\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"540.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the orders table's data</text><text x=\"540.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one file, two names (links: 2)</text><text x=\"540\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no extra disk, seconds at any size</text><text x=\"540\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">17 writes into the shared file:</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the way back is a backup</text></svg>", "caption": "pg_upgrade copies each data file or gives it a second name. Linking is fast because nothing is copied, and for the same reason the old cluster can never run again."}
```

A hard link is a second name for the same file. Ask for the inode number of the `orders` table's
file in both data directories:

```
ana@db:~$ sudo ls -li /var/lib/postgresql/16/rehearsal/base/16386/16393 /var/lib/postgresql/17/rehearsal/base/16386/16393
2197703 -rw------- 2 postgres postgres 68747264 Oct 10 04:43 /var/lib/postgresql/16/rehearsal/base/16386/16393
2197703 -rw------- 2 postgres postgres 68747264 Oct 10 04:43 /var/lib/postgresql/17/rehearsal/base/16386/16393
```

The same inode number on both lines, and a link count of **2**: one file of 68,747,264 bytes with two names.
No byte of the table was copied, which is why linking takes about the same time for a 125 MB
database and a 2 TB one. `du` sees it too, because it counts a file only once per invocation:

```
ana@db:~$ sudo du -sh /var/lib/postgresql/16/rehearsal /var/lib/postgresql/17/rehearsal
261M	/var/lib/postgresql/16/rehearsal
55M	/var/lib/postgresql/17/rehearsal
```

The new data directory adds only 55 MB of its own: a fresh catalogue and the WAL of a new cluster. Now try to start the old cluster:

```
ana@db:~$ sudo pg_ctlcluster 16 rehearsal start
Job for postgresql@16-rehearsal.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status postgresql@16-rehearsal.service" and "journalctl -xeu postgresql@16-rehearsal.service" for details.
ana@db:~$ sudo tail -n 5 /var/log/postgresql/postgresql-16-rehearsal.log
postgres: could not find the database system
Expected to find it in the directory "/var/lib/postgresql/16/rehearsal",
but could not open file "/var/lib/postgresql/16/rehearsal/global/pg_control": No such file or directory
pg_ctl: could not start server
Examine the log output.
```

**The old cluster cannot be started again**, and that is deliberate. Its files are the new cluster's
files, and 17 is already writing into them; a 16 started on the same files would read pages that
17 has changed and corrupt both. So `pg_upgrade` renamed `pg_control`, and the old server cannot
find it.

Which leaves the choice that `--link` is about:

- With `--link`, the upgrade takes seconds whatever the size and needs almost no extra disk. The
  way back is a **backup taken before you started**, restored onto a 16 server.
- Without it, every data file is copied. The upgrade takes as long as copying the data once,
  needs room for a second copy, and leaves the old cluster complete: if 17 misbehaves, you stop it
  and start 16 again.

On the 125 MB rehearsal the two are indistinguishable, which is another reason to rehearse on a copy
the size of production: the times you measure are the ones you will have.

## When the real upgrade comes

The same command upgrades `main` — `sudo pg_upgradecluster -m upgrade --link 16 main` — with one
step before it. It creates `17/main`, and **it refuses when a cluster with that name already
exists**, as the empty one the package made does. So the real run starts with
`sudo pg_dropcluster --stop 17 main`, after checking that nothing is in it. Do not run either on your
server now: this lesson ends with `main` still on 16.
