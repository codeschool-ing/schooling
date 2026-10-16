---
title: When the setup does not work
version: 1
---

Everything in this lesson can go wrong, and almost every way it goes wrong prints a sentence that
says which. Read the sentence before anything else. When it contains `FATAL:`, the part after it
is the server telling you exactly what it refused; when it does not, nothing answered at all.

## `psql: command not found`

```
ana@db:~$ psql --version
-bash: line 1: psql: command not found
```

The client is not installed on this machine. Either `apt install postgresql` was not run, or it
was run somewhere else — on your own computer rather than in the virtual machine, which is easy
to do with two terminals open. Check the prompt, then install it.

If `apt` stops and says it is **waiting for a lock**, another program is installing updates. A
new Ubuntu server does that by itself for a while after its first boot. Wait for it to finish;
never delete the lock file to get past it.

## `role "…" does not exist`

```
ana@db:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The server is running and does not know you. The `createuser` step was skipped, or was run as
somebody else. Run it, and the `createdb` after it:

```sh
sudo -u postgres createuser --superuser $USER
createdb $USER
```

If the message instead says `database "ana" does not exist`, the first command worked and the
second was skipped.

## `Peer authentication failed`

```
ana@db:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Instructions written for another system say to connect as `postgres`, and on Ubuntu that is
refused on purpose: over the local socket you may only be the role named like your operating-system
user. When you really need the `postgres` role, become the `postgres` user first, with
`sudo -u postgres psql`.

## `No such file or directory` — `Is the server running`

```
ana@db:~$ sudo systemctl stop postgresql
ana@db:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@db:~$ sudo systemctl start postgresql
```

No `FATAL:` this time, because nothing answered. The socket file exists only while the server
runs, and `pg_lsclusters` says `down`. Start it. **If it will not start, the reason is in the log**,
the file in the last column, and the last few lines say it in plain words:

```sh
sudo tail -n 20 /var/log/postgresql/postgresql-16-main.log
```

`systemctl status postgresql@16-main` shows the same lines, and so does
`journalctl -u postgresql@16-main`. A full disk, a configuration file you edited badly and a
port another program already holds are the three usual causes, and the log names each one.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has the
feature switched off**. It is a setting in the BIOS or UEFI menu, reached by a key pressed while
the computer starts, and the manufacturer's site says which key. On Windows, a hypervisor can also
refuse because Hyper-V or WSL already holds the processor's virtualisation; recent VirtualBox
releases run beside them, more slowly.

If the machine starts but is painfully slow, it probably has too little memory. Shut it down,
give it more in the hypervisor's settings, and start it again.

## Starting again

Nothing here is precious yet. A cluster can be removed and made again in two commands, and
lesson 4 explains what they do:

```sh
sudo pg_dropcluster --stop 16 main
sudo pg_createcluster --start 16 main
```

After those you are back where `apt install` left you, with no role for yourself, and the
`createuser` step is next. If the machine itself is in a state you cannot explain, delete it in the
hypervisor and make another: that is what a virtual machine is for, and a second installation
costs less than an evening of guessing.
