---
title: A minor upgrade with apt
version: 1
---

Your server is already on the newest minor release, because lesson 3 installed it from Ubuntu's
updates. **The session in this section was recorded on a server installed at 16.2**, the version
Ubuntu 24.04 was released with, with the same role and the same `shop` database as yours. On your
own server the commands below find nothing to do, and that is the right result.

## What is waiting

Refresh apt's lists and ask which PostgreSQL packages have a newer version:

```sh
sudo apt update
```

```
ana@db:~$ apt list --upgradable 2>/dev/null | grep postgresql
postgresql-16/noble-updates,noble-security 16.15-0ubuntu0.24.04.1 amd64 [upgradable from: 16.2-1ubuntu4]
postgresql-client-16/noble-updates,noble-security 16.15-0ubuntu0.24.04.1 amd64 [upgradable from: 16.2-1ubuntu4]
```

Two packages, the server and its client, and the pocket they come from: `noble-security`. That word
matters more than it looks, as the last part of this section explains. Before installing, ask the
server what it is and when it started:

```
ana@db:~$ psql -c "SELECT version();" -c "SELECT pg_postmaster_start_time();"
                                                         version                                                         
-------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 16.2 (Ubuntu 16.2-1ubuntu4) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.2.0-23ubuntu3) 13.2.0, 64-bit
(1 row)

   pg_postmaster_start_time    
-------------------------------
 2026-10-10 04:43:12.549419-03
(1 row)
```

## The upgrade

Install the newer server package. apt pulls in the client and `libpq5`, the client library, at the
same version:

```sh
sudo apt install postgresql-16
```

Then ask the same two questions again:

```
ana@db:~$ psql -c 'SELECT version();' -c 'SELECT pg_postmaster_start_time();'
                                                                 version                                                                  
------------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
(1 row)

   pg_postmaster_start_time    
-------------------------------
 2026-10-10 04:43:35.009418-03
(1 row)
```

**The version changed and so did the start time.** The package's scripts stopped the cluster,
replaced the programs under `/usr/lib/postgresql/16`, and started it again. Nothing in
`/var/lib/postgresql/16/main` was converted, because nothing needed to be. The server's own log says
the same thing from the inside:

```
ana@db:~$ sudo grep -E 'fast shutdown|system is shut down|starting PostgreSQL|ready to accept' /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:43:12.547 -03 [2478] LOG:  starting PostgreSQL 16.2 (Ubuntu 16.2-1ubuntu4) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.2.0-23ubuntu3) 13.2.0, 64-bit
2026-10-10 04:43:12.557 -03 [2478] LOG:  database system is ready to accept connections
2026-10-10 04:43:31.913 -03 [2478] LOG:  received fast shutdown request
2026-10-10 04:43:32.325 -03 [2478] LOG:  database system is shut down
2026-10-10 04:43:35.007 -03 [3987] LOG:  starting PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
2026-10-10 04:43:35.014 -03 [3987] LOG:  database system is ready to accept connections
```

Read the four lines in the middle. **`received fast shutdown request`** is the package stopping the
server: a fast shutdown rolls back every open transaction and disconnects every client. Between
`database system is shut down` and `ready to accept connections` the server did not exist, and on
the recording machine that gap was a few seconds — the time apt took to unpack three packages. That
is the whole cost of a minor upgrade, and every application connected at that moment sees its
connection drop and has to reconnect.

## Before you run it on a server that matters

**Read the release notes**, for every minor release between yours and the new one. Each has a
section called *Migration*, and almost always it says no action is needed. Occasionally it asks for
something: PostgreSQL 14.4 fixed a bug that could corrupt indexes built with `CREATE INDEX
CONCURRENTLY`, and its notes asked everybody to rebuild those indexes after updating. Skipping
straight from 16.2 to 16.15 means reading thirteen sets of notes, and that is still quicker than
finding the one that mattered afterwards.

**Choose the moment.** The restart is short, but it is a restart: choose a time when dropped
connections hurt least, and tell whoever owns the application.

**Know who else might choose it for you.** A standard Ubuntu server runs **unattended-upgrades**,
which installs packages from the security pocket automatically, once a day. PostgreSQL's minor
releases arrive in that pocket — `noble-security` in the list above — so a server left alone
upgrades itself and restarts the database at whatever time the timer fires. Some teams accept that.
Others list the PostgreSQL packages in `Unattended-Upgrade::Package-Blacklist` in
`/etc/apt/apt.conf.d/50unattended-upgrades` and upgrade them by hand, on a schedule, with somebody
watching. Either is a decision; finding out after the fact is not.
