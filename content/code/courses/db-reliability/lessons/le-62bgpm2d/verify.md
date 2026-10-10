---
title: Verify, and a success that says nothing
version: 1
---

Every file pgBackRest writes to the repository gets a checksum at backup time, and every archived
segment too. `verify` rereads all of it and compares. Here it is on the healthy repository:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify
ana@vm:~$ echo $?
0
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
stanza: main
status: ok
  archiveId: 16-1, total WAL checked: 3, total valid WAL: 3
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162747F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
```

Run plainly, **`verify` printed nothing and exited with 0.** Asked for its full report, it said what
it checked: three segments of log, two backups of 1271 files each, every file valid, `status: ok`.

Now damage one file inside the newest full backup, the way a failing disk, a bad copy or a careless
person would:

```
ana@vm:~$ sudo ls /var/lib/pgbackrest/backup/main
20261010-162742F
20261010-162747F
backup.history
backup.info
backup.info.copy
latest
ana@vm:~$ sudo sh -c 'echo junk >> /var/lib/pgbackrest/backup/main/20261010-162747F/pg_data/PG_VERSION.zst'
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify
ana@vm:~$ echo $?
0
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
stanza: main
status: error
  archiveId: 16-1, total WAL checked: 3, total valid WAL: 3
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162747F, status: invalid, total files checked: 1271, total valid files: 1270
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
ana@vm:~$ echo $?
0
```

Read that twice. The plain `verify` **printed nothing and exited with 0 again**, with a damaged
backup in the repository. The full report knows exactly what is wrong (one file of one backup with
an invalid checksum, `status: error`) and still exits with 0.

That is how version 2.50, the one Ubuntu 24.04 ships, behaves, and it is lesson 1's silent failure
inside a tool built to prevent silent failures. A job that runs `verify` and checks its exit status
is green for ever. **The report is the result**, and the only reliable test is to read it: the job
in the last section accepts exactly the line `status: ok` and nothing else, so that silence is a
failure and not a pass.

## Throwing a bad backup away

A backup that fails verification cannot be repaired; it can be removed and taken again:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info expire --set=20261010-162747F
2026-10-10 16:27:51.965 P00   INFO: expire command begin 2.50: --exec-id=1164-bcb4b129 --log-level-console=info --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --set=20261010-162747F --stanza=main
WARN: repo1: expiring latest backup 20261010-162747F - the ability to perform point-in-time-recovery (PITR) may be affected
      HINT: non-default settings for 'repo1-retention-archive'/'repo1-retention-archive-type' (even in prior expires) can cause gaps in the WAL.
2026-10-10 16:27:51.968 P00   INFO: repo1: expire adhoc backup 20261010-162747F
2026-10-10 16:27:51.970 P00   INFO: repo1: remove expired backup 20261010-162747F
2026-10-10 16:27:52.138 P00   INFO: expire command end: completed successfully (175ms)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
stanza: main
status: ok
  archiveId: 16-1, total WAL checked: 5, total valid WAL: 5
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162752F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
```

`expire --set` removed it, with a warning worth reading: it was the newest backup, and removing it
narrows the moments you can recover to until the next one exists. A new full backup closes that, and
the report is `ok` again, on two valid backups.

Two things remain outside what `verify` can see. It checks that the repository holds what
pgBackRest wrote, not that what it wrote was a healthy database; and it has never started a server
on any of it. The next section does that.
