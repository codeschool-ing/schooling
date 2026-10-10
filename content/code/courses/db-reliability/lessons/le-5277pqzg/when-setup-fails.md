---
title: When the setup does not work
version: 1
---

Every way the setup goes wrong prints a sentence saying which. Read it before anything else: the
part after `FATAL:` is the server telling you exactly what it refused.

## `role "…" does not exist`

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The server is running and does not know you. The `createuser` step was skipped, or was run on a
different machine from the one you are typing in. Run it:

```sh
sudo -u postgres createuser --superuser $USER
```

## `database "…" does not exist`

You got further: the server knows you, and you asked for a database that is not there. Without a
name `psql` asks for the one called like you. Name the one you meant, `psql shop`, and if that
answers the same, `createdb shop` was skipped.

## `Peer authentication failed for user "postgres"`

```
ana@vm:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Instructions written for other systems say to connect as `postgres`, and on Ubuntu that is refused
on purpose. A connection from the same machine is checked against **who you are on the computer**,
and you are not the computer's `postgres` user. Connect as yourself; and when you really need
`postgres`, become it first, with `sudo -u postgres psql`.

## `No such file or directory`, and `Is the server running`

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~$ sudo pg_ctlcluster 16 main start
```

No `FATAL:` this time, because nothing answered at all. The file `psql` looks for is the server's
door, a socket that exists only while the server runs, and `pg_lsclusters` confirms the server is
`down`. A virtual machine switched off rather than shut down, or a disk that filled up, both end
here, and in this course you will also end up here on purpose. If `start` fails, the reason is in
the last lines of the log named in the right-hand column:

```sh
sudo tail -n 20 /var/log/postgresql/postgresql-16-main.log
```

## `ERROR:` while `shop.sql` runs

The script stops being harmless if it was copied with a line missing: `psql` reports the line
number and carries on with the next statement, so the tables can end up half filled. Check the
counts in the section that loaded it, and if they differ, copy the script again with the copy
button rather than by selecting the text, and run it again. It drops both tables first, so a
second run starts clean.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has it
switched off.** It is a setting in the BIOS or UEFI menu, reached by a key pressed while the
computer starts, and the manufacturer's site says which key. If you cannot change it, the online
path needs no virtualisation on your side.

## Starting again

Nothing here is precious yet. `dropdb shop_restored` removes a database, and if the whole machine
is in a state you cannot explain, delete it and make another, or go back to the snapshot. This
course will ask you to do worse than that to it on purpose.
