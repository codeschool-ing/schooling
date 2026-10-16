---
title: Losing the first repository on purpose
version: 1
---

The second repository exists for the day the first is gone. Make that day happen: delete the local
repository entirely, as a failed disk or a careless command would.

```
ana@vm:~$ sudo rm -rf /var/lib/pgbackrest/archive /var/lib/pgbackrest/backup
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: mixed
        repo1: error (missing stanza path)
        repo2: ok
    cipher: mixed
        repo1: none
        repo2: aes-256-cbc

    db (current)
        wal archive min/max (16): 000000010000000000000004/000000010000000000000007

        full backup: 20261015-214449F
            timestamp start/stop: 2026-10-15 21:44:49-03 / 2026-10-15 21:44:53-03
            wal start/stop: 000000010000000000000006 / 000000010000000000000007
            database size: 33.8MB, database backup size: 33.8MB
            repo2: backup set size: 4.4MB, backup size: 4.4MB
shop=# SELECT archived_count, failed_count, last_failed_wal FROM pg_stat_archiver;
 archived_count | failed_count |     last_failed_wal      
----------------+--------------+--------------------------
              9 |            3 | 000000010000000000000008
(1 row)
```

`info` now reports `repo1` as an error, `missing stanza path`, and `repo2` as healthy, with its
backup. The live database never noticed, and the last query shows the one place it did: one order
and a switched segment later, `failed_count` is 3 and `last_failed_wal` names that segment.
pgBackRest pushes each segment to every repository it can reach and **reports the push as failed if
any repository failed**, so the server keeps retrying, lesson 4's alerts fire, and somebody is told
that one copy is gone while the other is still being written.

Restore from the survivor. `--repo=2` says where from, and the passphrase in the configuration
decrypts on the way:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ psql -X -A -t -p 5433 shop -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
```

The same report, the same answer: the second repository alone brought the shop back. It is lesson 5's
restore with one option added, which is the point. A second repository that needs a different
procedure on the worst day of the year is a second thing to get wrong.

Bring the first one back the way it would come back after a real failure, by creating the stanza
again and taking a fresh full backup into it:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main stanza-create
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=1 backup --type=full
shop=# SELECT archived_count, failed_count, last_archived_wal, last_failed_wal FROM pg_stat_archiver;
 archived_count | failed_count |            last_archived_wal             |     last_failed_wal      
----------------+--------------+------------------------------------------+--------------------------
             13 |            3 | 00000001000000000000000A.00000028.backup | 000000010000000000000008
(1 row)
```

Archiving recovers by itself: `archived_count` moves on, `failed_count` stays at the 3 attempts made
while `repo1` was missing, and the next backup in either repository is an ordinary one.
