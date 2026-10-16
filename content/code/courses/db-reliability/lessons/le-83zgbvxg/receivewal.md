---
title: Streaming the log instead of copying it
version: 1
---

`archive_command` sees a segment only once it is finished. Whatever is in the current, unfinished
segment is on the server alone, and `archive_timeout` only shortens that window. There is a second
way to collect the log that does not wait for a segment to end: receive it **as it is written**,
over the same replication protocol `pg_basebackup -X stream` used.

`pg_receivewal` is a client that does exactly that and writes what it receives into a directory, as
segments. It should run on another machine, so that it is a copy somewhere else; here it runs
beside the server, which shows the mechanism.

Before starting it, it asks the server for a **replication slot**. A slot is the server's promise to
keep every segment the client has not received yet, even while the client is disconnected, so that
a restart of `pg_receivewal` resumes where it stopped instead of finding the log it needed already
recycled. Then start it in the background, with the `&` at the end. Your shell answers with a job
number and a process id, which this transcript does not show:

```
ana@vm:~$ mkdir walstream
ana@vm:~$ pg_receivewal --create-slot --slot=walstream
ana@vm:~$ pg_receivewal -D walstream --slot=walstream > walstream.log 2>&1 &
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (9, 4400, now());
INSERT 0 1

shop=# SELECT pg_walfile_name(pg_current_wal_lsn());
     pg_walfile_name      
--------------------------
 00000001000000000000000F
(1 row)
ana@vm:~$ ls -l walstream
total 16384
-rw------- 1 ana ana 16777216 Oct 10 04:37 00000001000000000000000F.partial
```

The order went into segment `0F`, and `pg_receivewal` already has it: the file is called
`…0F.partial` because the segment is still being written, and it holds every record up to the last
one the server sent. When the server finishes the segment, the receiver renames it without the
suffix. **What the archive lacks is at most what the network has not delivered yet**, a fraction of
a second, rather than up to a whole segment or a whole `archive_timeout`.

## The slot's promise has a cost

Stop the receiver, and look at the slot it leaves behind:

```
shop=# SELECT slot_name, active, restart_lsn FROM pg_replication_slots;
 slot_name | active | restart_lsn 
-----------+--------+-------------
 walstream | f      | 0/F000000
(1 row)
ana@vm:~$ pg_receivewal --drop-slot --slot=walstream
```

`active` is `f`: nobody is connected to it. The slot is still there, and its `restart_lsn` says the
server must keep every segment from `0F` onwards for it, **for as long as it exists**. A receiver
that died on Friday and a slot nobody dropped is the same pile of segments as a broken archive
command, with no failed counter to say so. The last command drops the slot, which is what has to
happen whenever a receiver is retired. Lesson 11 meets slots again, as the thing that keeps a
replica's log, and puts a limit on how much they may hold.

## Which one to use

Many setups use both. The archive command (or the tool from lesson 5, which replaces it) is the
backup's backbone: every segment, verified, compressed, kept for as long as the retention says.
A streaming receiver is how a setup that cannot afford to lose even the last minute gets close to
zero, and with `--synchronous` it confirms each piece of log only once it is on its own disk. Even
then, **the server does not wait for it** unless it is told to: a commit returns before the
receiver has the record, so the loss is small and not zero. Making the server wait is synchronous
replication, lesson 12.
