---
title: Behind another credential
version: 1
---

The question to ask of every copy, after "what single event destroys it with the database", is:
**which credentials can delete it, and where do those credentials live?** In this lab the answer is
uncomfortable. `postgres` on the database server can delete everything in both repositories, because
it writes to both. Anybody who becomes `postgres`, or root, on that server can remove every backup
before touching the database, and in a ransomware attack that is the order things happen in.

There are three ways to put a backup behind a credential the database server does not hold.

## Pull instead of push

In the arrangement of lessons 5 and 9, the database server **pushes** its backups and segments to the
repository, so it needs write access, and with write access usually comes delete. The alternative is
a separate **backup server** that **pulls**: it holds the repository on its own disks, connects to
the database server to read from it, and the database server has no way in to the backup server at
all. pgBackRest supports exactly this, with the repository on a "repository host" reached over SSH,
and Barman is built around it. A compromised database server can then damage the database and
nothing else.

## Write without delete

Where the repository is object storage, the database server's credential can be allowed to **write
new objects and nothing more**: no delete, no overwrite, no change to the bucket's settings.
Retention is then done by a lifecycle rule on the bucket, or by a separate job with a separate
credential, and an object lock makes even that wait for the retention date.

## Another account, other people

The strongest separation is administrative. The offsite repository lives in **another account**,
ideally another provider, whose administrators are not the database's administrators and whose
credentials are not stored on any machine the database runs on, protected by a second factor. Losing
the primary cloud account, to an attacker or to a billing dispute, then leaves the backups where
they were.

None of these was typed in this lab, which is one machine and one administrator. They are listed
because they are the difference between "we have offsite backups" and "we have backups the person
who broke into the database server cannot delete", and lesson 10 is about the day that difference is
the only one that matters.
