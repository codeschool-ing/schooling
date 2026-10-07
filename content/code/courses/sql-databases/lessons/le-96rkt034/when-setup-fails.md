---
title: When the setup does not work
version: 1
---

Everything in the last section can go wrong, and every way it goes wrong prints a sentence that
says which. Read the sentence before anything else: the part after `FATAL:` is the server telling
you exactly what it refused.

## `role "…" does not exist`

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The server is running and does not know you. The `createuser` step was skipped, or was run in a
different machine from the one you are typing in. Run it:

```sh
sudo -u postgres createuser --superuser $USER
```

## `database "…" does not exist`

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

You got further: the server knows you, and you asked for a database that is not there. Without a
name `psql` asks for the one called like you. Name the one you meant — `psql shop` — and if that
answers the same, `createdb shop` was skipped.

## `Peer authentication failed for user "postgres"`

```
ana@vm:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Instructions written for another system say to connect as `postgres`, and on Ubuntu that is
refused on purpose. A connection from the same machine is checked against **who you are on the
computer**, and you are not the computer's `postgres` user. Connect as yourself, which the last
section made possible; and when you really need `postgres`, become it first, with
`sudo -u postgres psql`.

## `No such file or directory` — `Is the server running`

```
ana@vm:~$ psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
```

No `FATAL:` this time, because nothing answered at all. The file `psql` looks for is the server's
door, and it exists only while the server runs. Ask, and start it:

```
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~$ sudo pg_ctlcluster 16 main start
```

`down` was the answer. A virtual machine that was switched off rather than shut down, or a disk
that filled up, both end here. If `start` fails, the reason is in the last lines of the log in
the right-hand column — `sudo tail /var/log/postgresql/postgresql-16-main.log` — and a full disk
says so in plain words.

## `psql: command not found`

The client is not installed, or this is not the machine you installed it on. Inside the virtual
machine it is `sudo apt install -y postgresql` again. On a computer with PostgreSQL installed
some other way, the installer put `psql` in a directory the shell does not search, and its own
instructions say which one to add.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has the
feature switched off.** It is a setting in the BIOS or UEFI menu, reached by a key pressed while
the computer starts, and the manufacturer's site says which key. If you cannot change it, the
installed path or the online one in the first section needs no virtualisation at all.

## Starting again

Nothing here is precious yet. A database is removed with `dropdb shop` and made again with
`createdb shop`; and if the machine itself is in a state you cannot explain, delete it in the
hypervisor and make another. That is what a virtual machine is for, and a second installation is a
small price for knowing exactly what you are standing on.
