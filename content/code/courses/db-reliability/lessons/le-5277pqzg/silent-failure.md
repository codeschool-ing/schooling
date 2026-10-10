---
title: The backup that succeeded and holds nothing
version: 1
---

Here is the most common backup command on the internet, with one typing mistake in it. The
database is called `shop` and the command says `shpo`:

```
ana@vm:~$ pg_dump shpo | gzip > shop.sql.gz
pg_dump: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "shpo" does not exist
ana@vm:~$ echo $?
0
ana@vm:~$ ls -l shop.sql.gz
-rw-r--r-- 1 ana ana 20 Oct 10 03:23 shop.sql.gz
```

`pg_dump` failed, said so, and **the command as a whole reported success**. A shell pipeline's exit
status is the status of its last program, and the last program was `gzip`, which compressed what
it was given perfectly. It was given nothing. The result is a valid gzip file of twenty bytes, with
today's date, in the right place, with the right name.

Now imagine that line in a nightly job written two years ago. The database was renamed last
spring. The error went to a log nobody reads, the job's status went to a dashboard that shows green
for an exit code of zero, and the backup directory holds a neat row of twenty-byte files, one per
night. Every check that looks at the job passes. **The only check that fails is a restore.**

## The fix for the shell, and why it is not the real fix

Bash can be told to fail a pipeline when any program in it fails:

```
ana@vm:~$ set -o pipefail
ana@vm:~$ pg_dump shpo | gzip > shop.sql.gz
pg_dump: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "shpo" does not exist
ana@vm:~$ echo $?
1
```

`set -o pipefail` belongs at the top of every backup script you write, together with `set -e` and
`set -u`, and lesson 5 puts it there. It turns this particular failure into a red job.

It does not turn every failure into a red job, and that is the point of this section. A dump can
exit with success and still be the wrong thing: the wrong database, one schema of three, a server
that was a replica and was months behind. The size of the file is a better clue than the exit code
(twenty bytes, half a megabyte), and still only a clue. What catches all of them is what the last
section did: **put the data back, and ask it the questions only the real data answers.**

## What a job should check, at the least

Every backup job in this course ends with three checks, cheapest first:

1. **Every program in it succeeded**, with `pipefail` and `set -e` so a failure stops the job.
2. **The output is plausible**: it exists, it is not tiny, and it is not much smaller than last
   night's. A tool can do this for you, and lesson 5's does.
3. **It has been restored somewhere and checked**, often enough that a failure is found while the
   previous good copy still exists. Lesson 7 decides how often that is.

The first two are monitoring. Only the third is a backup.
