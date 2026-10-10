---
title: Fast, whole and blind: what a physical backup trades
version: 1
---

Lesson 2 timed a logical restore of `bigshop`. Do the same with a base backup of the whole server,
`bigshop`, the shop and everything else on it, and a restore by copying:

```
ana@vm:~$ rm -rf base
ana@vm:~$ time pg_basebackup -D base -X stream -c fast

real	0m1.311s
user	0m0.064s
sys	0m0.809s
ana@vm:~$ du -sh base
318M	base
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ time { sudo cp -a base /var/lib/postgresql/16/restore && sudo chown -R postgres:postgres /var/lib/postgresql/16/restore && sudo chmod 700 /var/lib/postgresql/16/restore && sudo pg_ctlcluster 16 restore start; }

real	0m3.813s
user	0m0.069s
sys	0m1.201s
ana@vm:~$ psql -X -A -t -p 5433 bigshop -c "SELECT count(*) FROM orders"
3000000
```

**1.3 seconds to take the backup and 3.8 to restore it and start the server**, for 318 MB, against
7.3 seconds for lesson 2 to restore `bigshop` alone from its dump. Nothing was rebuilt. The indexes
came back as files, already built, and the keys were never checked because nothing about them had
changed. The time a physical restore takes grows with the size of the files and the speed of the
disk and the network, and **not with how many indexes and constraints there are**, which is what
made the logical restore of a terabyte an eight-hour job.

That speed is paid for in three ways, and each one is a reason to keep lesson 2's dumps as well.

## Whole server, or nothing

A base backup is one server's data directory. There is no way to restore one database out of it, or
one table: the files of every database share a write-ahead log and a commit record, and none of
them makes sense alone. Getting back lesson 2's Curitiba orders from a physical backup means
restoring **the whole server somewhere else**, then copying the rows out of it, which is the
selective restore again, with a bigger first step.

## Same version, same kind of machine

The files are PostgreSQL 16's on-disk format, on this processor's architecture. A base backup
starts only on **the same major version** (any 16.x) and the same kind of processor; it does not
start on 17, and a backup of an Intel server does not start on an ARM one. Upgrades and migrations
between machines stay with the logical tools.

## Faithful to the damage

A page of a table that was corrupted on the server is copied as it is, verified as correct by the
manifest (the bytes are the ones the server sent) and restored as it was. A physical backup has no
opinion about the data, only about the files. A dump, which has to read every row through the
database to write it, would have failed on that page. That is the strongest reason to keep both
kinds: **they fail differently**, and a failure that defeats one is usually visible to the other.

## The question it leaves open

A base backup is still one moment, the instant its copy ended. A disk that fails sixteen hours
after the nightly base backup loses sixteen hours, exactly as a dump does; only faster to restore.
Lesson 4 keeps the write-ahead log the server writes between backups, and the base backup becomes
the starting point of a recovery that can stop anywhere after it.
