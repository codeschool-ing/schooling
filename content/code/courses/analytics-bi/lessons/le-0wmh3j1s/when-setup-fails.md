---
title: When the setup does not work
version: 1
---

Everything in the last two sections can go wrong, and nearly every way it goes wrong prints a
sentence that says which. Read the sentence before anything else.

## `Connection refused` from `ssh`

```
$ ssh -p 2222 ana@localhost
ssh: connect to host localhost port 2222: Connection refused
```

Nothing on your computer's port 2222 answered. Either the forwarding rule is missing — on
VirtualBox it is added with the machine switched off, and a typo in either port number has the
same effect — or the machine is not running, or the OpenSSH server was never installed. The last
one is fixed from the machine's own window: `sudo apt install -y openssh-server`.

## The script stopped halfway

A paste that lost its last lines, or a line broken in two by the editor, gives a script that runs
until the broken statement and stops there. With the first 100 lines of the 165:

```
ana@vm:~$ psql -q lantern -f short.sql
psql:short.sql:3: NOTICE:  drop cascades to 7 other objects
DETAIL:  drop cascades to table products
drop cascades to table customers
drop cascades to table orders
drop cascades to table order_lines
drop cascades to table web_sessions
drop cascades to table web_events
drop cascades to view order_totals
psql:short.sql:100: ERROR:  missing FROM-clause entry for table "d"
LINE 9: SELECT d.order_id, d.n AS line_no, p.product_id,
               ^
ana@vm:~$ psql -q lantern -f lantern.sql >/dev/null 2>&1
```

The `ERROR` names the line where `psql` gave up, and the table of counts never arrives because the
script never reached it. **A missing table of counts is the symptom to look for.** Open the file
again, delete everything, paste the whole block once more, and run it again: the script starts
by dropping what the broken run left, so a second run is always safe.

## `database "…" does not exist`

```
ana@vm:~$ psql lantern2
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "lantern2" does not exist
```

The server is running, it knows you, and the name you asked for is not one of its databases. A
typo is the usual reason; `createdb lantern` having been skipped is the other. `psql -l` lists the
databases that exist.

## `role "…" does not exist`

```
ana@vm:~$ psql lantern
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
Cluster is already running.
NOTICE:  database "lantern" does not exist, skipping
psql:/tmp/lantern.sql:3: NOTICE:  schema "shop" does not exist, skipping
```

The server is running and does not know you: the `createuser` step was skipped, or was run on a
different machine from the one you are typing in. Run it:

```sh
sudo -u postgres createuser --superuser $USER
```

## `No such file or directory` — `Is the server running`

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ psql lantern
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@vm:~$ sudo pg_ctlcluster 16 main start
```

No `FATAL:` this time, because nothing answered at all: the file `psql` looks for exists only
while the server runs. A virtual machine that was switched off rather than shut down, or a disk
that filled up, both end here. `sudo pg_ctlcluster 16 main start` starts it, and if that fails,
the reason is in the last lines of `/var/log/postgresql/postgresql-16-main.log`.

## The counts differ from the lesson's

If the script ran to the end and printed five counts that are not 12, 2650, 7102, 11362 and
108987, the script is not the one in the lesson — compare the first and last lines of your file
with the block — or the server is not PostgreSQL 16. The numbers come from PostgreSQL's random
number generator started from a fixed seed, and they were recorded on version 16; `psql
--version` says which you have.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has the
feature switched off.** It is a setting in the BIOS or UEFI menu, reached by a key pressed while
the computer starts. If you cannot change it, the installed path in this lesson needs no
virtualisation at all.
