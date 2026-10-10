---
title: The manifest, and what checking it proves
version: 1
---

A backup sits on a disk for weeks before anybody needs it, and disks, networks and people change
files. The manifest `pg_basebackup` wrote is the means of finding out whether this directory is
still the one the server sent. The program that reads it is not on your `PATH`: Ubuntu installs the
less common PostgreSQL tools under the version's own directory, so it is typed in full.

```
ana@vm:~$ /usr/lib/postgresql/16/bin/pg_verifybackup base
backup successfully verified
ana@vm:~$ echo "tampered" | sudo tee -a base/global/pg_control > /dev/null
ana@vm:~$ /usr/lib/postgresql/16/bin/pg_verifybackup base
pg_verifybackup: error: "global/pg_control" has size 8201 on disk but size 8192 in the manifest
```

The first run read the manifest, then every file, and compared each file's size and checksum with
what the server recorded while sending it. Then one line of text was appended to `pg_control`, the
small file holding the server's own record of its state, and **the check failed on the exact file
and the exact difference**. A copy damaged in that way would have started a server that believed
something false about itself, or refused to start at all.

The damaged copy is thrown away and taken again:

```
ana@vm:~$ rm -rf base
ana@vm:~$ pg_basebackup -D base -X stream -c fast
ana@vm:~$ /usr/lib/postgresql/16/bin/pg_verifybackup base
backup successfully verified
```

## What it proves, and what it does not

`pg_verifybackup` answers one question: **are these the bytes the server sent?** It also checks
that the write-ahead log needed to make the copy consistent is present and readable. That makes it
the right thing to run on every backup, cheaply, as the second of lesson 1's three checks.

It does not answer whether the database inside is sound. If a table's file was already damaged on
the server, the backup is a faithful copy of the damage and verifies perfectly. Nor does it say
whether the copy can be started and queried. **Only a restore answers that**, so a verified backup
is still lesson 1's "a claim until it is restored", with one class of failure ruled out.

There are two checks in PostgreSQL worth knowing beside it, both outside this lesson: data checksums,
which make the server itself detect a damaged page when it reads one (they were `disabled` in
lesson 2's `initdb` output, the default on Ubuntu, and lesson 5's tool checks them when they are on),
and `pg_amcheck`, which inspects tables and indexes for corruption on a running server.
