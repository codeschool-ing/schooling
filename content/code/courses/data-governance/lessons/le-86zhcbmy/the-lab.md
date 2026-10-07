---
title: The lab, and three ways to build it
version: 1
---

**Nobody learns access control by reading a grant.** You learn it when a query you expected to
work answers `permission denied`, or when one you expected to fail returns six thousand rows. So
every lesson here is run, on a machine you build yourself, and the platform gives you none: the
lab is yours, on your own computer.

It is one Linux machine with:

- **PostgreSQL 16**, in a cluster of its own called `gov` on port 5433, holding Ipê's database,
  `ipe`. Three schemas — `sales`, `health` and `support` — and seven tables, loaded with 6,012
  customers and seven years of orders.
- **OpenBao**, a key-management server, installed but not started. Lesson 4 starts it.
- **A small certificate authority** of the lab's own, which lesson 3 uses to give the database a
  certificate a client can check.

The script that builds it is `lab.sh`, published with this course's source, with the data
generator and the schema in `lab/` beside it. It creates a user called `ana`, installs the
packages it needs, generates the data and loads it. Once it has run, this is the machine:

```
ana@lab:~/gov$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/gov$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  gov     5433 online postgres /var/lib/postgresql/16/gov  /var/log/postgresql/postgresql-16-gov.log
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`main` is the cluster Ubuntu creates when PostgreSQL is installed. The lab leaves it alone and
builds `gov` beside it, so that nothing you do in this course touches a database you had before.

## Three ways to run it

**In a virtual machine — recommended.** An Ubuntu 24.04 virtual machine with 2 GB of memory and
10 GB of free disk is enough. `lab.sh` adds users, a database server, a key-management server and
entries in `/etc/hosts`, and it gives `ana` the right to use `sudo` without a password. That is
exactly the kind of change you do not want on the computer you work on. `virtualization` lesson 4
builds a virtual machine in VirtualBox if you have never made one. Inside it:

```sh
sudo bash lab.sh up
```

**Installed on a Linux computer of your own.** Possible, and the script is idempotent, but read it
first: it edits `/etc/hosts`, writes `/etc/postgresql-common/user_clusters` and adds a sudoers
file. If any of those is a file you care about, use the virtual machine.

**In containers, for most of it.** The official `postgres:16` image runs the database lessons, and
OpenBao publishes an image too. You would load `lab/schema.sql` and the generated files yourself,
and the paths in the transcripts — `/etc/postgresql/16/gov`, the log under `/var/log/postgresql` —
will be different in a container. The course was not recorded that way; it is named so that a
student who cannot run a virtual machine still has a path.

## Two lines the lessons assume

Ubuntu's `psql` asks a small wrapper which cluster to talk to. The lab tells it `gov` and the
database `ipe`, but a connection by host name does not ask the wrapper, so the port has to be in
the environment as well. `lab.sh` adds this to `ana`'s `~/.bashrc`; if you build the lab another
way, add it yourself:

```sh
export PGPORT=5433 PGDATABASE=ipe
```

The lab also maps two names to the machine itself, `db.ipe.example` and `bao.ipe.example`, so that
lesson 3 can check a certificate against a name rather than against an address.

## When the setup fails

Three failures account for most of it, and each one says so:

- **`apt-get` cannot reach the archive.** The packages are not there and the first `psql`
  answers `command not found`. A proxy or a firewall is the usual cause. Once
  `sudo apt-get install postgresql-16` works by hand, the script works too.
- **The OpenBao download fails its checksum.** The script stops rather than install a binary it
  cannot vouch for. Delete nothing; run it again, and if it fails twice, the file on the network
  is not the one the script pins, which is worth knowing before you run it.
- **Port 5433 is taken.** `pg_createcluster` refuses. Something else on the machine is listening
  there; in a fresh virtual machine nothing is.

If something else fails, read the last ten lines the script printed. It stops at the first error
rather than carrying on, so the last line is the one that broke. `sudo bash lab.sh reset` throws
the database and `~/gov` away and builds them again from the files, which is also how you start a
lesson over.
