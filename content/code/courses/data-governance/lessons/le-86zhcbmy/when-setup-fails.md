---
title: When the setup fails
version: 1
---

Most failures in the last two sections are one of these, and each one says so in its last line:

- **`E: Unable to locate package postgresql-16`.** The machine is not Ubuntu 24.04, whose archive
  carries PostgreSQL 16. On another release, either start again from a 24.04 image — the simplest
  answer — or add the PostgreSQL project's own apt repository, which publishes 16 for the supported
  releases of Ubuntu and Debian.
- **`apt-get` cannot reach the archive.** A proxy, a firewall or no network. Nothing else will work
  until `sudo apt-get update` does.
- **`pg_createcluster` says the cluster already exists**, because a step was run twice. Drop it and
  build it again: `sudo pg_dropcluster --stop 16 gov`, then step 3.
- **Port 5433 is in use.** Something else is listening there, and `sudo ss -ltnp | grep 5433` says
  what. In a fresh virtual machine nothing is.
- **`psql: error: connection to server on socket … failed: No such file or directory`.** The cluster
  is not running. Start it with `sudo pg_ctlcluster 16 gov start`; if that fails, the last lines of
  `/var/log/postgresql/postgresql-16-gov.log` say why, and a typing mistake in the four lines added
  to `postgresql.conf` is the usual one.
- **`FATAL: database "ipe" does not exist`.** Expected until section 5 creates it.
- **`could not open file … for reading: Permission denied`** during the `\copy`. The `chmod` line
  was skipped, so `postgres` cannot read the files.

## Starting over

Everything in the database can be rebuilt from the two files in `~/gov`. If a later lesson leaves the
lab in a state you cannot explain, drop the cluster, create it again with step 3 of section 4, and
load the data again as section 5 does:

```sh
sudo pg_dropcluster --stop 16 gov
```

The files in `/var/lib/ipe-data` do not need generating again, since they are the same every time.
What you lose is what the lessons built — roles, grants, keys — and the lessons build on each other
in order, so you type them again from lesson 1 up to where you were.