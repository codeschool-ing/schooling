---
title: A full write-ahead log
version: 1
---

The log's filesystem from two sections ago has 116 MB free, and `max_wal_size` lets the log grow
to about a gigabyte before a checkpoint recycles it. Nothing stops the gap from being reached. A
copy of `orders` and a few inserts into it write the log fast enough:

```
shop=# CREATE TABLE walfill AS SELECT * FROM orders;
SELECT 1000000
```

```
ana@db:~$ for i in 1 2 3 4 5 6; do psql shop -c "INSERT INTO walfill SELECT * FROM orders" || break; done
INSERT 0 1000000
INSERT 0 1000000
INSERT 0 1000000
PANIC:  could not write to file "pg_wal/xlogtemp.449": No space left on device
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
connection to server was lost
```

**`PANIC` is the severity above `FATAL`, and it ends the whole server**, not one statement or one
session. A transaction that cannot write its log record cannot be made durable, and PostgreSQL will
not carry on pretending otherwise. Every connection to the server was dropped, not only this one.

## The server does not come back by itself

```
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@db:~$ df -h /srv/wal
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      488M  449M  3.4M 100% /srv/wal
ana@db:~$ sudo grep -E "PANIC|terminated by signal|redo done|FATAL|shut down" /var/log/postgresql/postgresql-16-main.log | tail -n 7
2026-10-10 16:48:27.282 -03 [339] LOG:  database system was shut down at 2026-10-10 16:48:26 -03
2026-10-10 16:48:40.247 -03 [449] ana@shop PANIC:  could not write to file "pg_wal/xlogtemp.449": No space left on device
2026-10-10 16:48:40.252 -03 [336] LOG:  server process (PID 449) was terminated by signal 6: Aborted
2026-10-10 16:48:40.869 -03 [450] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-10 16:48:42.478 -03 [450] LOG:  redo done at 0/33FFFF98 system usage: CPU: user: 1.32 s, system: 0.21 s, elapsed: 1.60 s
2026-10-10 16:48:42.485 -03 [450] FATAL:  could not write to file "pg_wal/xlogtemp.450": No space left on device
2026-10-10 16:48:42.505 -03 [336] LOG:  database system is shut down
```

Read the log in order. The backend that hit the full disk panicked and was killed. The
postmaster did what lesson 8 showed it does after a crash: it threw every process away and started
crash recovery. Recovery replayed the log to its end, `redo done`, and then had to **write** a new
log file to finish, on the same full filesystem. It failed, and the postmaster gave up and shut
down. Starting it again by hand ends the same way, for the same reason.

The 3.4 MB that `df` shows free is the reserve again, which `postgres` cannot use. Two things are
tempting here and both are wrong:

- **Deleting files from `pg_wal`.** They look like old logs and they are the only copy of changes
  not yet in the data files; removing one loses committed data or makes the cluster impossible to
  recover. `pg_resetwal` is the program that throws the log away on purpose, it is a last resort
  after everything else has failed, and it can leave the database inconsistent.
- **Lowering `max_wal_size` to make room.** The server has to be running to recycle anything, and
  it cannot start.

## Giving it room

The way out is space. On a virtual machine you would grow its virtual disk in the hypervisor and
then the filesystem; here the "disk" is a file, so the same two steps are `truncate` and
`resize2fs`. ext4 can grow while mounted, but nothing is using this one now, so unmount it and
check it first:

```
ana@db:~$ sudo systemctl stop postgresql@16-main
ana@db:~$ sudo umount /srv/wal
ana@db:~$ sudo truncate -s 2G /srv/wal.img
ana@db:~$ sudo e2fsck -f -p /srv/wal.img
/srv/wal.img: 41/32768 files (7.3% non-contiguous), 121043/131072 blocks
ana@db:~$ sudo resize2fs /srv/wal.img
resize2fs 1.47.0 (5-Feb-2023)
Resizing the filesystem on /srv/wal.img to 524288 (4k) blocks.
The filesystem on /srv/wal.img is now 524288 (4k) blocks long.

ana@db:~$ sudo mount -o loop /srv/wal.img /srv/wal
ana@db:~$ df -h /srv/wal
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      2.0G  449M  1.4G  24% /srv/wal
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:48:45.901 -03 [524] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-10 16:48:45.903 -03 [524] LOG:  redo starts at 0/18F7F9E0
2026-10-10 16:48:47.673 -03 [524] LOG:  redo done at 0/33FFFF98 system usage: CPU: user: 1.43 s, system: 0.18 s, elapsed: 1.77 s
2026-10-10 16:48:47.721 -03 [522] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-10 16:48:48.129 -03 [522] LOG:  checkpoint complete: wrote 16386 buffers (100.0%); 0 WAL file(s) added, 0 removed, 28 recycled; write=0.080 s, sync=0.265 s, total=0.409 s; sync files=27, longest=0.186 s, average=0.010 s; distance=442881 kB, estimate=442881 kB; lsn=0/34000058, redo lsn=0/34000058
2026-10-10 16:48:48.138 -03 [521] LOG:  database system is ready to accept connections
ana@db:~$ psql shop -c "SELECT count(*) FROM walfill"
  count  
---------
 4000000
(1 row)
```

The cluster was already down; the `stop` makes systemd agree before its filesystem goes. With room to write, recovery ran exactly as before and then finished: an
**end-of-recovery checkpoint**, which recycled 28 log files, and `ready to accept connections`.

**Four million rows: the copy and the three inserts that committed.** The fourth insert was running
when the server panicked, never committed, and is not there. Nothing that was reported as
committed was lost, which is the write-ahead log keeping the promise lesson 7 described, even
through this.

## Why it filled, and what watches for it

This disk filled because it was smaller than `max_wal_size`, on purpose. On a real server the
usual causes are a replication slot nobody is reading, which lesson 7 named, and an archive
command that keeps failing, which `db-reliability` covers with archiving; in both, the log is kept
because something still needs it, and it grows until the disk ends. **Watch free space on the log's
filesystem and alert well before it is full**, and when it fills anyway, lesson 24 writes the
runbook for that night.

## Putting everything back

The rest of the course expects `pg_wal` inside the data directory and no extra filesystems:

```
shop=# DROP TABLE walfill;
DROP TABLE

shop=# DROP TABLE filler;
DROP TABLE

shop=# DROP TABLESPACE small;
DROP TABLESPACE
```

```
ana@db:~$ sudo systemctl stop postgresql@16-main
ana@db:~$ sudo rm /var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo mv /srv/wal/pg_wal /var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo umount /srv/wal /srv/small
ana@db:~$ sudo rm /srv/wal.img /srv/small.img && sudo rmdir /srv/wal /srv/small
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`rm` on `pg_wal` removed only the link, and the directory it pointed at came back to where it was.
