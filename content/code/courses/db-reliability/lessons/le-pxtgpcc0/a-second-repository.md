---
title: A second repository, encrypted, with its own retention
version: 1
---

pgBackRest can keep the same stanza in up to four repositories at once. Every archived segment goes
to all of them; each backup goes to the one you name; each repository has its own retention and its
own encryption. That is the mechanism for the "1 offsite" of the last section, and it changes one
file.

In this lab the second repository is a directory, `/srv/offsite`, on the same machine, standing in
for a bucket at a storage provider or a disk in another building. What follows works unchanged when
`repo2` is an S3 bucket, an Azure container or a Google Cloud bucket, with that service's settings in
place of `repo2-path`; this lab has no such service, so those settings were not run here.

## The passphrase first

The offsite copy will be encrypted, so it needs a passphrase, and the passphrase has to be long,
random and **written down somewhere other than this machine** before the first byte is encrypted
with it. Generate one:

```sh
openssl rand -base64 48
```

Sixty-four characters of noise. Keep them where your organisation keeps its most important secrets,
and the section on the key explains why that is not optional.

## The configuration

Replace `/etc/pgbackrest.conf` with this, with your passphrase in place of the placeholder:

```schooling-example
{"language": "ini", "file": "pgbackrest.conf", "parts": [{"code": "[global]\nrepo1-path=/var/lib/pgbackrest\nrepo1-retention-full=2", "note": "The local repository from lesson 5, unchanged: fast to restore from, and on the same machine."}, {"code": "repo2-path=/srv/offsite/pgbackrest\nrepo2-retention-full=4\nrepo2-cipher-type=aes-256-cbc\nrepo2-cipher-pass=PASTE-YOUR-PASSPHRASE-HERE", "note": "The second repository: somewhere else, kept longer, and encrypted, because its storage belongs to somebody else."}, {"code": "compress-type=zst\nstart-fast=y\n\n[main]\npg1-path=/var/lib/postgresql/16/main", "note": "The settings that apply to both."}]}
```

The second repository needs a directory that `postgres` owns, and the file now holds a secret, so it
is tightened too: readable by `postgres`, which runs pgBackRest, and by nobody else but root.

```
ana@vm:~$ sudo mkdir -p /srv/offsite/pgbackrest
ana@vm:~$ sudo chown postgres:postgres /srv/offsite/pgbackrest
ana@vm:~$ sudo chmod 750 /srv/offsite/pgbackrest
ana@vm:~$ sudo chown root:postgres /etc/pgbackrest.conf
ana@vm:~$ sudo chmod 640 /etc/pgbackrest.conf
ana@vm:~$ ls -l /etc/pgbackrest.conf
-rw-r----- 1 root postgres 310 Oct 15 21:44 /etc/pgbackrest.conf
```

Then create the stanza in the new repository. `stanza-create` sees that `repo1` already has it and
creates it only where it is missing:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info stanza-create
2026-10-15 21:44:45.866 P00   INFO: stanza-create command begin 2.50: --exec-id=3470-3e69405a --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo2-cipher-pass=<redacted> --repo2-cipher-type=aes-256-cbc --repo1-path=/var/lib/pgbackrest --repo2-path=/srv/offsite/pgbackrest --stanza=main
2026-10-15 21:44:46.472 P00   INFO: stanza-create for stanza 'main' on repo1
2026-10-15 21:44:46.472 P00   INFO: stanza 'main' already exists on repo1 and is valid
2026-10-15 21:44:46.472 P00   INFO: stanza-create for stanza 'main' on repo2
2026-10-15 21:44:46.483 P00   INFO: stanza-create command end: completed successfully (619ms)
```

## Backups go where they are sent

Archived segments now go to both repositories without being asked. Backups do not: `backup` writes to
`repo1` unless told otherwise, so the second repository gets its own:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: mixed
        repo1: none
        repo2: aes-256-cbc

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000007

        full backup: 20261015-214441F
            timestamp start/stop: 2026-10-15 21:44:41-03 / 2026-10-15 21:44:45-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000003
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB

        incr backup: 20261015-214441F_20261015-214447I
            timestamp start/stop: 2026-10-15 21:44:47-03 / 2026-10-15 21:44:48-03
            wal start/stop: 000000010000000000000004 / 000000010000000000000005
            database size: 33.8MB, database backup size: 8.3KB
            repo1: backup set size: 4.4MB, backup size: 389B
            backup reference list: 20261015-214441F

        full backup: 20261015-214449F
            timestamp start/stop: 2026-10-15 21:44:49-03 / 2026-10-15 21:44:53-03
            wal start/stop: 000000010000000000000006 / 000000010000000000000007
            database size: 33.8MB, database backup size: 33.8MB
            repo2: backup set size: 4.4MB, backup size: 4.4MB
```

The plain `backup` went to `repo1`, where lesson 5's full backup already was, so pgBackRest made an
**incremental** there, a few hundred bytes. The `--repo=2` one had to be a full, since nothing was
in `repo2` to build on. `info` now lists backups from both repositories in one history, each line
saying which repository holds it, and `cipher: mixed` says one of them is encrypted. Look at the same
file in each:

```
ana@vm:~$ sudo file /var/lib/pgbackrest/backup/main/20261015-214441F/pg_data/PG_VERSION.zst /srv/offsite/pgbackrest/backup/main/20261015-214449F/pg_data/PG_VERSION.zst
/var/lib/pgbackrest/backup/main/20261015-214441F/pg_data/PG_VERSION.zst:     Zstandard compressed data (v0.8+), Dictionary ID: None
/srv/offsite/pgbackrest/backup/main/20261015-214449F/pg_data/PG_VERSION.zst: openssl enc'd data with salted password
```

`file` reads the first bytes of each and recognises them: the copy in `repo1` is zstd, the copy in
`repo2` is `openssl enc'd data with salted password`. Whoever holds the bucket, the disk or the tape
holds nothing they can read without the passphrase.

The nightly job of lesson 5 gains one line, `pgbackrest --stanza=main --repo=2 backup`, after the
first backup and before the verify, so that both repositories receive a backup every night.
