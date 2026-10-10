---
title: Installing PostgreSQL from Ubuntu's packages
version: 1
---

A fresh Ubuntu server has no database on it, and asking for the client proves it:

```
ana@db:~$ psql --version
-bash: line 1: psql: command not found
```

Two commands install the server, the `psql` client and everything they need:

```sh
sudo apt update
sudo apt install -y postgresql
```

`sudo` asks for your password, and `apt` prints a screen of progress for a minute or two. The
package called `postgresql` is a small one whose only job is to pull in the current major version
for this release of Ubuntu — on 24.04 that is `postgresql-16`. Its last lines mention creating a
**cluster**, which is PostgreSQL's word for one running server and the directory its data lives
in. The word is older than the modern sense of "a group of machines", and it means one server
here. Ask what you got:

```
ana@db:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

**Read that version string once, because lesson 20 depends on it.** `16` is the **major version**;
`.15` is the fifteenth **minor release** of it, which carries bug and security fixes and nothing
else. The part in brackets is Ubuntu's own packaging of that release. Your number may be higher:
Ubuntu publishes each minor release as an ordinary update.

`pg_lsclusters` is not part of PostgreSQL. It comes from **postgresql-common**, Debian and
Ubuntu's layer around it, which lets one machine run several clusters, even of different major
versions, side by side. Every cluster has a version and a name — here `16` and `main` — and the
row tells you the four things you ask about any server: its port, whether it is up, where its
data is and where it writes its log.

## The service

systemd started the cluster the moment it was installed, and it starts it again at every boot:

```
ana@db:~$ systemctl status postgresql@16-main --no-pager
● postgresql@16-main.service - PostgreSQL Cluster 16-main
     Loaded: loaded (/usr/lib/systemd/system/postgresql@.service; enabled-runtime; preset: enabled)
     Active: active (running) since Sat 2026-10-10 03:28:12 -03; 789ms ago
    Process: 2482 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 16-main start (code=exited, status=0/SUCCESS)
   Main PID: 2487 (postgres)
        CPU: 148ms
     CGroup: /system.slice/system-postgresql.slice/postgresql@16-main.service
             ├─2487 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
             ├─2488 "postgres: 16/main: checkpointer "
             ├─2489 "postgres: 16/main: background writer "
             ├─2491 "postgres: 16/main: walwriter "
             ├─2492 "postgres: 16/main: autovacuum launcher "
             └─2493 "postgres: 16/main: logical replication launcher "
```

The unit is `postgresql@16-main`: one **template**, `postgresql@.service`, with the cluster's
version and name after the `@`. A second cluster would be a second instance of the same template.
There is also a plain `postgresql.service`, which does nothing of its own and passes `start`,
`stop` and `restart` to every cluster on the machine; `sudo systemctl restart postgresql` is the
short form you will see in most instructions, and on a machine with one cluster the two mean the
same thing.

The tree under `CGroup` is the server itself. **The first line is the postmaster**, the process
started with the data directory after `-D` and the configuration file after `config_file`. The
five below it are the background workers it started, each named after its job. Lessons 7 and 8
are about the checkpointer and the WAL writer, lesson 14 about the autovacuum launcher. Every
client that connects will add one more process to that list, and lesson 10 is about why that
matters.
