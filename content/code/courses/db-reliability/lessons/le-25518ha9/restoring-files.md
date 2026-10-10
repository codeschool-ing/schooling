---
title: Restoring a base backup
version: 1
---

Restoring a physical backup has four steps, and none of them involves SQL: stop the server that
will receive it, put the files where its data directory is, give them to the user the server runs
as, and start it. The target is the second server from lesson 2, on port 5433, whose own data is
about to be replaced entirely.

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo cp -a base /var/lib/postgresql/16/restore
ana@vm:~$ sudo chown -R postgres:postgres /var/lib/postgresql/16/restore
ana@vm:~$ sudo chmod 700 /var/lib/postgresql/16/restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
ana@vm:~$ sudo tail -n 6 /var/log/postgresql/postgresql-16-restore.log
2026-10-10 04:14:59.318 -03 [4295] LOG:  completed backup recovery with redo LSN 0/2D000028 and end LSN 0/2D000100
2026-10-10 04:14:59.318 -03 [4295] LOG:  consistent recovery state reached at 0/2D000100
2026-10-10 04:14:59.318 -03 [4295] LOG:  redo done at 0/2D000100 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
2026-10-10 04:14:59.410 -03 [4293] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-10 04:14:59.416 -03 [4293] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.002 s, sync=0.001 s, total=0.007 s; sync files=2, longest=0.001 s, average=0.001 s; distance=16384 kB, estimate=16384 kB; lsn=0/2E000028, redo lsn=0/2E000028
2026-10-10 04:14:59.421 -03 [4292] LOG:  database system is ready to accept connections
```

`cp -a` keeps the files' times and permissions, and the next two lines fix the rest: the backup
was written by you, and a PostgreSQL server refuses to start on a directory that anyone but its own
user can read. The `chmod 700` is not a formality, and leaving it out is the commonest way this
restore fails, with a message in the log saying exactly that.

The log is where the restore can be watched. The server found `backup_label`, replayed the
write-ahead log from the backup's start point to its end point (`completed backup recovery`), and
reported **`consistent recovery state reached`**: the copy is now one moment, the moment the backup
ended. Then it ran a checkpoint and opened. Those lines are the physical equivalent of
`pg_restore` exiting with 0, and they deserve the same suspicion:

```
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ psql -X -A -t -p 5433 shop -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
ana@vm:~$ psql -p 5433 -l
                                                   List of databases
   Name    |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 bigshop   | ana      | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 shop      | ana      | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
(5 rows)
```

The report agrees, and the list of databases shows the difference from lesson 2 at a glance:
**the whole server came back**, `bigshop` included, without anybody naming it. There was no
`createdb`, no globals file and no role to create first, because roles live in the data directory
like everything else and were copied with it.

That is the shape of every physical restore in this course. Lesson 5's tool automates the copying,
and lesson 6 adds one setting that tells the server to keep replaying past the end of the backup,
up to a moment you choose.
