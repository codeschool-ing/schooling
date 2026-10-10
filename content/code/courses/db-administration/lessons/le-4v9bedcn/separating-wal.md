---
title: Giving the write-ahead log its own filesystem
version: 1
---

The data files and the write-ahead log are written in completely different ways. **The log is
appended to in order and flushed at every commit**, with a session waiting on each flush. The
data files are written in the background, in bursts, by the checkpointer and the background writer
from lessons 7 and 8, and nobody waits on them directly. Putting the two on separate disks keeps
a checkpoint's burst of writes from queueing in front of the next commit's flush.

There is a second reason, and on a small server it is the stronger one: **the two fail
differently when they run out of space.** A full data filesystem fails statements. A full log
filesystem stops the server. The last two sections of this lesson show both, and having them on
separate filesystems means one can fill without the other.

What it does not buy is speed on a virtual machine whose disks are all files on the same physical
drive, which is what the course's server is. Separation helps when the two filesystems are on
different devices. On your server it is practice for a move you will make on one that has them.

## Sizing it

`pg_wal` has to hold everything since the last checkpoint and then some, and lesson 7 named the
setting that decides how much: `max_wal_size`. Measure what is there now and read the setting
before choosing a size:

```
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
337M	/var/lib/postgresql/16/main/pg_wal
ana@db:~$ psql shop -Atc "SHOW max_wal_size"
1GB
```

**A filesystem for `pg_wal` should be comfortably bigger than `max_wal_size`**, because that limit
is soft: it is the point at which a checkpoint is asked for, and WAL keeps arriving while the
checkpoint runs. Twice the setting is a reasonable floor, and more if replication or archiving
can hold files back, which lesson 7 and `db-reliability` cover.

The filesystem below is 512 MB, **half of `max_wal_size`, which is deliberately too small**. The
last section of this lesson needs a log disk that fills; never size a real one like this.

## Moving it

A new cluster can be created with its log elsewhere from the start, with `initdb --waldir`. An
existing one is moved by stopping it, moving the directory and leaving a symbolic link where it
was. The new filesystem here is a file formatted as ext4 and mounted through a loop device, which
behaves like a second disk without needing one:

```
ana@db:~$ sudo truncate -s 512M /srv/wal.img
ana@db:~$ sudo mkfs.ext4 -q /srv/wal.img
ana@db:~$ sudo mkdir /srv/wal
ana@db:~$ sudo mount -o loop /srv/wal.img /srv/wal
ana@db:~$ sudo systemctl stop postgresql@16-main
ana@db:~$ sudo mv /var/lib/postgresql/16/main/pg_wal /srv/wal/pg_wal
ana@db:~$ sudo -u postgres ln -s /srv/wal/pg_wal /var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main | grep pg_wal
lrwxrwxrwx 1 postgres postgres   15 Oct 10 16:48 pg_wal -> /srv/wal/pg_wal
ana@db:~$ df -h /srv/wal
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      488M  337M  116M  75% /srv/wal
```

`truncate` made a 512 MB file without writing 512 MB, and `mkfs.ext4 -q` formatted it quietly.
**The server must be stopped while `pg_wal` moves**: a running server writing into a directory
that is half copied is how a cluster is lost. The 337 MB came along, and the filesystem was left
with 116 MB free. It reports 488 MB rather than 512 because ext4 keeps some of every filesystem
for its own bookkeeping, and some more for the root user, which the next section uses.

On a real server the new filesystem also gets a line in `/etc/fstab`, like the one in the
previous section. Without it, the next boot leaves `/srv/wal` empty, the link points at nothing,
and the cluster cannot start, which is at least loud.
