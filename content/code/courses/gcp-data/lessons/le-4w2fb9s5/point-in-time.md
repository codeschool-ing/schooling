---
title: Point-in-time recovery, practised on PostgreSQL
version: 1
---

**Point-in-time recovery is a base backup and every change since, replayed up to a moment you
choose.** A backup taken last night holds the database as it was last night. The write-ahead log holds
every change made after it, in order, with the time each transaction committed. Restore the backup,
replay the log, and stop just before the mistake: the database as it was at 15:46:55 on a Friday,
with every order up to that second and none of the damage after it.

**Cloud SQL does exactly this when point-in-time recovery is on**, with the backups of the next
section and the log it keeps beside them, and the result is always a **new instance**. The command is
a clone:

```sh
gcloud sql instances clone quitanda-orders quitanda-orders-before-delete \
  --point-in-time='2026-10-30T18:46:55Z'
```

That was not run. The reference says how to write the time, and it is the detail people get wrong:

```
ana@laptop:~/gcp$ gcloud sql instances clone --help | sed -n '/^       --point-in-time=/,/^$/p'
       --point-in-time=POINT_IN_TIME
          Represents the state of an instance at any given point in time inside
          a transaction log file. For MySQL, the binary log file is used for
          transaction logs. For PostgreSQL, the write-ahead log file is used
          for transaction logs. For SQL Server, the log backup file is used for
          such purpose. To create a transaction log, enable point-in-time
          recovery on the source instance. Instance should have transaction
          logs accumulated up to the point in time they want to restore up to.
          Uses RFC 3339 format in UTC timezone. If specified, defines a past
          state of the instance to clone. For example,
          '2012-11-15T16:19:00.094Z'.
```

**RFC 3339, in UTC.** 15:46:55 in São Paulo is `18:46:55Z`. And how far back the moment can be is the
log retention of lesson 6's editions table, which the reference states for the flag that sets it:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --retained-backups-count=/,/^$/p;/^     --retained-transaction-log-days=/,/^$/p'
     --retained-backups-count=RETAINED_BACKUPS_COUNT
        How many backups to keep. The valid range is between 1 and 365. Default
        value is 7 for Enterprise edition instances. For Enterprise_Plus,
        default value is 15. Applicable only if --no-backups is not specified.

     --retained-transaction-log-days=RETAINED_TRANSACTION_LOG_DAYS
        How many days of transaction logs to keep. The valid range is between 1
        and 35. Only use this option when point-in-time recovery is enabled. If
        logs are stored on disk, storage size for transaction logs could
        increase when the number of days for log retention increases. For
        Enterprise, default and max retention values are 7 and 7 respectively.
        For Enterprise_Plus, default and max retention values are 14 and 35.
```

**Seven days on Enterprise, and seven is also the most; up to 35 on Enterprise Plus.** A mistake found
on day eight of an Enterprise instance is past the reach of the log, and only a backup from before it
can help, at that backup's moment and not at the second you wanted.

The rest of this section is **PostgreSQL on the laptop**: the archive Cloud SQL keeps for you, set up
by hand, and a recovery to a moment, run by hand. The two servers of the previous section are still up.

## Archiving the log

**PostgreSQL recycles its log files once a checkpoint no longer needs them**, so keeping them for
recovery is a setting: `archive_mode` turns archiving on, and `archive_command` is the shell command
the server runs for each finished segment, with `%p` its path and `%f` its file name. The command here
copies into `~/gcp/pg/archive`, which is `../archive` from the data directory the server runs in, and
refuses to overwrite a segment already there:

```
ana@laptop:~/gcp$ mkdir -p ~/gcp/pg/archive
ana@laptop:~/gcp$ psql -c 'ALTER SYSTEM SET archive_mode = on' -c "ALTER SYSTEM SET archive_command = 'test ! -f ../archive/%f && cp %p ../archive/%f'"
ALTER SYSTEM
ALTER SYSTEM
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -l ~/gcp/pg/orders.log restart -m fast
waiting for server to shut down.... done
server stopped
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -Atc 'SHOW archive_mode'
on
ana@laptop:~/gcp$ psql -Atc 'SELECT state FROM pg_stat_replication'
streaming
```

**`archive_mode` is a `postmaster` setting**, lesson 6's context column again, so it needed the
restart. The replica reconnected on its own after it; `streaming` says so.

## A base backup, and then the mistake

```
ana@laptop:~/gcp$ pg_basebackup -D ~/gcp/pg/base -c fast && ls ~/gcp/pg/archive
000000010000000000000003
000000010000000000000004
000000010000000000000004.00000028.backup
```

The base backup is the same command as the replica's, without `-R`, into `~/gcp/pg/base`. The archive
now holds the segments written so far, and a small `.backup` file that marks where in the log the
backup started. Now note the time, and then make the mistake every database eventually meets:

```
ana@laptop:~/gcp$ psql -Atc 'SELECT now()'
2026-10-30 15:46:55.877432-03
ana@laptop:~/gcp$ psql -c 'DELETE FROM orders' -c 'SELECT pg_switch_wal()' > /dev/null && sleep 1 && psql -Atc 'SELECT count(*) FROM orders' && psql -p 5434 -Atc 'SELECT count(*) FROM orders'
0
0
ana@laptop:~/gcp$ ls ~/gcp/pg/archive
000000010000000000000003
000000010000000000000004
000000010000000000000004.00000028.backup
000000010000000000000005
```

**Zero on the primary and zero on the replica.** The `DELETE` without a `WHERE` reached the replica
within the second, as the previous sections said it would. `pg_switch_wal()` closed the current log
segment so the server archived it at once rather than when it filled. On Cloud SQL the log reaches
its archive on a schedule of Google's, which is why the latest moment you can recover to is a little
behind the present.

## Recovering to the moment before

**Recovery starts from the base backup, never from the damaged directory.** Copy it, and mark the copy
for recovery with `recovery.signal`, the sister of the replica's `standby.signal`: recover, then
stop and become a server of your own. Three settings say where the log is, how far to replay, and what
to do on arriving:

```
ana@laptop:~/gcp$ cp -a ~/gcp/pg/base ~/gcp/pg/restored && touch ~/gcp/pg/restored/recovery.signal
ana@laptop:~/gcp$ printf "restore_command = 'cp ../archive/%%f %%p'\nrecovery_target_time = '2026-10-30 15:46:55.877432-03'\nrecovery_target_action = 'promote'\n" >> ~/gcp/pg/restored/postgresql.auto.conf && tail -3 ~/gcp/pg/restored/postgresql.auto.conf
restore_command = 'cp ../archive/%f %p'
recovery_target_time = '2026-10-30 15:46:55.877432-03'
recovery_target_action = 'promote'
```

**The time is the one `SELECT now()` printed**, with its offset, `-03`, which is what lets PostgreSQL
read São Paulo's time correctly. Start the copy on a port of its own, 5435, and read what it did:

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/restored -o "-p 5435 -k $HOME/gcp/pg" -l ~/gcp/pg/restored.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ sleep 2 && grep -E 'starting point-in-time|recovery stopping|selected new timeline' ~/gcp/pg/restored.log | cut -d' ' -f4-
[28834] LOG:  starting point-in-time recovery to 2026-10-30 15:46:55.877432-03
[28834] LOG:  recovery stopping before commit of transaction 733, time 2026-10-30 15:46:56.905418-03
[28834] LOG:  selected new timeline ID: 2
ana@laptop:~/gcp$ psql -p 5435 -Atc 'SELECT count(*), max(id) FROM orders'
1100|1100
```

**`recovery stopping before commit of transaction 733`** is the `DELETE`, committed a second after the
target, and the server stopped just short of it. **`selected new timeline ID: 2`** is the restored
server beginning a history of its own, branching from the original's at the target; this is what
lets the same archive hold both. And **1,100 orders, the last one 1,100**: everything up to the
moment, including the hundred written while the replica was paused, and none of the damage.

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/restored stop && pg_ctl -D ~/gcp/pg/reports stop && pg_ctl -D ~/gcp/pg/orders stop
waiting for server to shut down.... done
server stopped
waiting for server to shut down.... done
server stopped
waiting for server to shut down.... done
server stopped
```

**The original was not touched.** It still has no orders, and the restored copy sits beside it on
another port. That is exactly the shape of Cloud SQL's clone: a new instance, with a new address,
beside the old one. Somebody then decides whether to point the application at the clone or to copy
the missing rows back into the original, and that decision is a person's, not a command's.
