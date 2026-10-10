---
title: Installing pgBackRest, and the stanza
version: 1
---

Install it from Ubuntu's packages:

```sh
sudo apt install -y pgbackrest
```

```
ana@vm:~$ pgbackrest version
pgBackRest 2.50
```

pgBackRest works on **repositories** and **stanzas**. A repository is where the backups and the
archived log are kept; a stanza is one PostgreSQL server's backups inside it, under a name you
choose. One repository can hold the stanzas of many servers, and one stanza can be copied to more
than one repository, which lesson 9 does.

Its configuration is one file, `/etc/pgbackrest.conf`. The package installs an example there;
replace it with this, using `sudo nano /etc/pgbackrest.conf` or any editor run with `sudo`:

```schooling-example
{"language": "ini", "file": "pgbackrest.conf", "parts": [{"code": "[global]\nrepo1-path=/var/lib/pgbackrest", "note": "Settings that apply to everything. The repository is a directory on this machine for now; lesson 9 moves a copy of it somewhere else."}, {"code": "repo1-retention-full=2", "note": "Keep two full backups, with everything that depends on them. The next section shows what that deletes, and when."}, {"code": "compress-type=zst", "note": "Compress with zstd, which is fast and small. The default, gzip, is slower for the same size."}, {"code": "start-fast=y\n", "note": "Ask the server for an immediate checkpoint at the start of a backup, like pg_basebackup's -c fast."}, {"code": "[main]\npg1-path=/var/lib/postgresql/16/main", "note": "The stanza, called main after the cluster. pg1-path is the data directory pg_lsclusters showed in lesson 1."}]}
```

pgBackRest runs as the operating system's `postgres` user, the one that owns the data directory,
and every command in this lesson starts with `sudo -u postgres`.

## The archive command, replaced

Lesson 4 archived with `cp`. pgBackRest has its own command for the job, `archive-push`, which
compresses each segment, checksums it, writes it to the repository and makes sure it reached the
disk before reporting success:

```
shop=# ALTER SYSTEM SET archive_mode = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %p';
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
```

If you still have lesson 4's settings, this replaces them; the restart is needed only if
`archive_mode` was off.

## Creating the stanza, and checking it

`stanza-create` makes the stanza's directories in the repository and records which server it
belongs to. `check` then proves the whole path works, end to end: it asks the server to switch
segments and waits until that segment arrives in the repository through `archive_command`. Both are
quiet unless told otherwise, so these two ask for their log at `info`:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info stanza-create
2026-10-10 16:27:29.544 P00   INFO: stanza-create command begin 2.50: --exec-id=981-2fbfb15f --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --stanza=main
2026-10-10 16:27:30.152 P00   INFO: stanza-create for stanza 'main' on repo1
2026-10-10 16:27:30.156 P00   INFO: stanza-create command end: completed successfully (614ms)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info check
2026-10-10 16:27:30.184 P00   INFO: check command begin 2.50: --exec-id=988-b010d3cf --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --stanza=main
2026-10-10 16:27:30.789 P00   INFO: check repo1 configuration (primary)
2026-10-10 16:27:30.990 P00   INFO: check repo1 archive for WAL (primary)
2026-10-10 16:27:30.990 P00   INFO: WAL segment 000000010000000000000002 successfully archived to '/var/lib/pgbackrest/archive/main/16-1/0000000100000000/000000010000000000000002-457829d86e276a258a6ad80bbebeff102a1e45a5.zst' on repo1
2026-10-10 16:27:30.990 P00   INFO: check command end: completed successfully (807ms)
```

The line that matters is **`WAL segment … successfully archived`**: the server finished a segment,
ran `archive-push`, and the segment reached the repository. `check` is the cheapest test there is
of the archiving path, and the nightly job at the end of this lesson runs it first.
