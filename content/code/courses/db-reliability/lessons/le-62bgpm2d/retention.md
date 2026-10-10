---
title: Retention: what is deleted, and when
version: 1
---

The configuration says `repo1-retention-full=2`: keep two full backups. Take two more, and watch
the second one's `expire`:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info backup --type=full
2026-10-10 16:27:46.502 P00   INFO: backup command begin 2.50: --compress-type=zst --exec-id=1078-73b31b1a --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main --start-fast --type=full
2026-10-10 16:27:47.240 P00   INFO: execute non-exclusive backup start: backup begins after the requested immediate checkpoint completes
2026-10-10 16:27:47.741 P00   INFO: backup start archive = 00000001000000000000000C, lsn = 0/C0000D0
2026-10-10 16:27:47.741 P00   INFO: check archive for prior segment 00000001000000000000000B
2026-10-10 16:27:50.100 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2026-10-10 16:27:50.301 P00   INFO: backup stop archive = 00000001000000000000000C, lsn = 0/C0362A8
2026-10-10 16:27:50.303 P00   INFO: check archive for segment(s) 00000001000000000000000C:00000001000000000000000C
2026-10-10 16:27:50.309 P00   INFO: new backup label = 20261010-162747F
2026-10-10 16:27:50.333 P00   INFO: full backup size = 33.9MB, file total = 1271
2026-10-10 16:27:50.333 P00   INFO: backup command end: completed successfully (3833ms)
2026-10-10 16:27:50.333 P00   INFO: expire command begin 2.50: --exec-id=1078-73b31b1a --log-level-console=info --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main
2026-10-10 16:27:50.336 P00   INFO: repo1: expire full backup set 20261010-162731F, 20261010-162731F_20261010-162736D, 20261010-162731F_20261010-162739I
2026-10-10 16:27:50.338 P00   INFO: repo1: remove expired backup 20261010-162731F_20261010-162739I
2026-10-10 16:27:50.341 P00   INFO: repo1: remove expired backup 20261010-162731F_20261010-162736D
2026-10-10 16:27:50.343 P00   INFO: repo1: remove expired backup 20261010-162731F
2026-10-10 16:27:50.534 P00   INFO: repo1: 16-1 remove archive, start = 000000010000000000000003, stop = 000000010000000000000009
2026-10-10 16:27:50.534 P00   INFO: expire command end: completed successfully (201ms)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 00000001000000000000000A/00000001000000000000000C

        full backup: 20261010-162742F
            timestamp start/stop: 2026-10-10 16:27:42-03 / 2026-10-10 16:27:46-03
            wal start/stop: 00000001000000000000000A / 00000001000000000000000A
            database size: 33.9MB, database backup size: 33.9MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB

        full backup: 20261010-162747F
            timestamp start/stop: 2026-10-10 16:27:47-03 / 2026-10-10 16:27:50-03
            wal start/stop: 00000001000000000000000C / 00000001000000000000000C
            database size: 33.9MB, database backup size: 33.9MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB
```

Read the four `expire` lines in order. With a third full backup in the repository, the oldest one
is past the limit, so pgBackRest expired **the whole set that depended on it**: the full, the
differential and the incremental, in one decision, removing the dependants first. Then it removed
the archived segments that only that set needed, `…03` to `…09`, and nothing after them. `info`
confirms it: two full backups, and `wal archive min/max` now starting at `…0A`, the first segment
the oldest remaining backup needs.

That last step is the one a script of your own gets wrong. Segments `…0A` onwards stay because a
restore from the older remaining full needs every one of them; deleting by age (anything older than
a week, say) would have deleted log a kept backup still depends on, and **nothing would have
reported it until somebody tried to recover past the gap**.

## The window you actually have

Retention decides how far back you can go. With two full backups kept, and one taken every Sunday,
the oldest restorable moment is between eight and fourteen days ago, depending on the day you look:
just after a Sunday backup, the older full is a week old; just before the next, it is nearly two.
Counting full backups rather than days means the window shrinks if a weekly full is taken twice by
mistake, and grows if one fails.

pgBackRest can count in days instead (`repo1-retention-full-type=time`). Which to use depends on
what has been promised, and the promise belongs to lesson 8: "we can restore any moment of the last
14 days" is a sentence somebody signs, and retention is the setting that keeps it true.

## Deleting by hand

`expire` can also remove one named backup, with `--set`. That is what to do with a backup known to
be bad, and the verify section uses it. It is the only deletion in this lesson that is not
automatic, and pgBackRest still refuses to leave a dependent backup without the backup it needs.
