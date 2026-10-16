---
title: What a script of your own leaves out
version: 1
---

Lessons 3 and 4 built a backup out of parts: `pg_basebackup` for the files, `cp` in
`archive_command` for the log, and nothing yet to delete either. That set works, and a team that
writes its own script around it usually discovers the missing pieces one incident at a time. The
list is long enough that nobody should write it again:

- **Retention that understands dependencies.** Deleting old base backups is easy. Deleting the
  archived segments only those backups needed, and none that a newer backup still needs, is the
  part people get wrong, and the mistake shows up as a recovery that stops at a gap months later.
- **Copies that are only what changed.** A full copy of a 2 TB database every night is 2 TB of
  reading and writing every night. A backup that copies only what changed since the last one is
  most of the saving.
- **Compression and parallelism.** Both for the files and for every archived segment.
- **Proof the archive reached the disk**, which `cp` never gave.
- **Verification**: a checksum for every file at backup time, and a command that rereads the whole
  repository and checks every file against it.
- **A restore that knows where everything is**, including which segments to fetch.

Several tools do this for PostgreSQL. **pgBackRest** is the one this course uses: it is in Ubuntu's
own packages, it does everything on that list, and it has been the default choice of a lot of
PostgreSQL teams for years. **Barman** is the other common one, built around a separate backup
server that pulls from the database; **WAL-G** is popular with teams that keep everything in object
storage. The ideas in this lesson (stanzas aside, which are pgBackRest's word) carry across all
three, and so do the failures.

One thing the tool does not change: **it is still a claim until it is restored.** pgBackRest makes
the copies better, faster and verifiable. It cannot know whether the restored database is the one
the application needs, and a later section of this lesson finds a place where even its own check
has to be read carefully.
