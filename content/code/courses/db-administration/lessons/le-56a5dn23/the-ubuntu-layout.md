---
title: What Ubuntu keeps outside the data directory
version: 1
---

On a server built from the PostgreSQL project's own instructions, the data directory holds
everything: `postgresql.conf`, `pg_hba.conf` and the log, all beside `base/`. Debian and Ubuntu move
three things out, and **knowing which three is half of finding anything on a server you inherit**.

## The configuration, in /etc

```
ana@db:~$ ls -l /etc/postgresql/16/main
total 60
drwxr-xr-x 2 postgres postgres  4096 Oct 10 03:18 conf.d
-rw-r--r-- 1 postgres postgres   315 Oct 10 03:18 environment
-rw-r--r-- 1 postgres postgres   143 Oct 10 03:18 pg_ctl.conf
-rw-r----- 1 postgres postgres  5924 Oct 10 03:18 pg_hba.conf
-rw-r----- 1 postgres postgres  2640 Oct 10 03:18 pg_ident.conf
-rw-r--r-- 1 postgres postgres 30243 Oct 10 03:18 postgresql.conf
-rw-r--r-- 1 postgres postgres   317 Oct 10 03:18 start.conf
```

`postgresql.conf` and `pg_hba.conf` are the two lesson 5 is about, and `pg_ident.conf` is the map
lesson 11 uses. `conf.d/` is an empty directory the main file reads at the end, which is where a
change of yours belongs rather than in the 30 kB file itself. The other three belong to
postgresql-common:

| file | what it decides |
|---|---|
| `start.conf` | whether the cluster starts at boot: `auto`, `manual` or `disabled` |
| `environment` | environment variables the server is started with |
| `pg_ctl.conf` | extra options for `pg_ctl`, the program that starts and stops the server |

```
ana@db:~$ cat /etc/postgresql/16/main/start.conf | grep -v "^#"

auto
```

Everything but the comments: `auto`. A cluster you keep for a rehearsal and do not want running
after every reboot is set to `manual`.

Moving the configuration out of the data directory buys one thing: **the data directory becomes
pure data**. It can be wiped and rebuilt, restored from a backup or replaced by a copy from another
server without losing a single setting, and `/etc` is where every other service on the machine
keeps its configuration anyway.

## The log and the socket

```
ana@db:~$ ls -l /var/log/postgresql /var/run/postgresql
/var/log/postgresql:
total 4
-rw-r----- 1 postgres adm 560 Oct 10 04:11 postgresql-16-main.log

/var/run/postgresql:
total 4
-rw-r--r-- 1 postgres postgres 4 Oct 10 04:11 16-main.pid
```

The log is one file per cluster, named after its version and name, readable by the group `adm` so
an administrator does not need to become `postgres` to read it. Ubuntu rotates it once a week with
logrotate. Lesson 19 is about what goes into it.

`/var/run/postgresql` holds the socket you met in lesson 3, which `ls` does not show because its
name starts with a dot, and `16-main.pid`, postgresql-common's own record of the server's process.

## Making and removing clusters

Because one machine can hold several clusters, postgresql-common has commands to make and remove
them, and lesson 3 used two of them to start again:

```sh
sudo pg_dropcluster --stop 16 main
sudo pg_createcluster --start 16 main
```

`pg_dropcluster --stop` stops the cluster and deletes **its data directory, its configuration
directory and its log** — the three places this section and the last one described. Nothing is
kept and nothing asks twice. `pg_createcluster` runs `initdb`, the program that makes an empty data
directory, writes a fresh configuration into `/etc/postgresql/16/main`, and with `--start` starts it.
The new cluster has only the `postgres` role in it, as on the day you installed.

A second cluster beside the first takes a different name and gets the next free port:
`sudo pg_createcluster 16 rehearsal` would make `/var/lib/postgresql/16/rehearsal` listening on
5433. Lesson 20 does exactly that to rehearse an upgrade without touching `main`.
