---
title: A copy nobody can delete, and who that nobody includes
version: 1
---

Encryption decides who can read a backup. It does nothing about who can **delete** one, and deletion
is what lesson 10's attacker does first: a backup that can be removed by the same person, program
or stolen credential that can damage the database is a backup that disappears together with it.

An **immutable** copy is one that cannot be changed or deleted, by anybody, until a date. On Linux a
file system can mark files that way with `chattr +i`; make the offsite full backup immutable, then
try to delete part of it, first by hand and then through pgBackRest, after taking a newer full so
that retention would allow the older one to go:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 backup --type=full
ana@vm:~$ sudo chattr -R +i /srv/offsite/pgbackrest/backup/main/20261015-214449F
ana@vm:~$ sudo lsattr -d /srv/offsite/pgbackrest/backup/main/20261015-214449F
----i---------e------- /srv/offsite/pgbackrest/backup/main/20261015-214449F
ana@vm:~$ sudo rm /srv/offsite/pgbackrest/backup/main/20261015-214449F/backup.manifest
rm: cannot remove '/srv/offsite/pgbackrest/backup/main/20261015-214449F/backup.manifest': Operation not permitted
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 expire --set=20261015-214449F
ERROR: [060]: repo2: unable to remove '/srv/offsite/pgbackrest/backup/main/20261015-214449F/backup.manifest': [1] Operation not permitted
ERROR: [104]: expire command encountered 1 error(s), check the log file for details
```

`lsattr` shows the `i` flag. Root could not remove a single file, and **pgBackRest's own `expire`
failed on the same file**. That second refusal is the point: retention, a script with a bug, and an
attacker who has taken over the `postgres` account all delete through the same mechanism, and the
flag stops all three.

Which also means the flag has to agree with retention. A backup marked immutable for longer than the
retention keeps it makes `expire` fail every night, and a nightly job that fails every night is one
nobody reads. Immutability is set for a period, and that period is chosen together with
`repo2-retention-full`.

## The limit of doing it on the same machine

```
ana@vm:~$ sudo chattr -R -i /srv/offsite/pgbackrest/backup/main/20261015-214449F
ana@vm:~$ sudo lsattr -d /srv/offsite/pgbackrest/backup/main/20261015-214449F
--------------e------- /srv/offsite/pgbackrest/backup/main/20261015-214449F
```

Root removed the flag as easily as it set it. On one machine, `chattr +i` protects against
**mistakes**: a wrong path in a cleanup, a script deleting the wrong directory, an `expire` with the
wrong argument. It does not protect against somebody who has root on that machine, and somebody who
has broken into the database server is often exactly that.

Real immutability lives **where the attacker's credentials do not reach**:

- **Object storage with a retention lock.** S3's Object Lock in compliance mode, and its equivalents
  at other providers, refuse to delete or overwrite an object before its retention date, whatever
  credentials are used, including the account's own administrator. pgBackRest writes to such a
  bucket like any other, and the lock is set on the bucket, by somebody else, once.
- **Media that is physically offline**: a tape or a disk taken out and put on a shelf. Slow to
  restore from, and no network attack reaches it.
- **A backup server the database server cannot log into**, which the next section is about.

This lab has neither a bucket with object lock nor a tape, so those are described here rather than
typed. The test of each is the same one this section ran: try to delete it with the strongest
credential you have, and expect to fail.
