---
title: A backup is a claim until it is restored
version: 1
---

Ask a team whether its database is backed up and the answer is almost always yes. Ask what that
yes rests on and the answer is a job: something runs every night and reports success. **That is a
statement about a job, not about the data.** It says a program started, did something, and exited
without complaining. Whether the bytes it left behind can become a working database again is a
separate question, and the only way to answer it is to do it.

## The chain, and where it breaks

Between the rows in a live database and the same rows running again after a disaster there is a
chain, and each link can fail without saying so:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A chain of six boxes: the live database, the backup job, the copy, where it is kept, the restore and the check. Under each of the first five, a failure that leaves the job reporting success. A bracket over the first two says what a green job proves; a bracket over all six says what a restore proves.\"><defs><marker id=\"l1c-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"12\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the live database</text><path d=\"M116 108 L128 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"64\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">dumps the wrong</text><text x=\"64\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">database</text><rect x=\"130\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the backup job</text><path d=\"M234 108 L246 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"182\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a pipe hides</text><text x=\"182\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the error</text><rect x=\"248\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the copy</text><path d=\"M352 108 L364 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"300\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">roles and keys</text><text x=\"300\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">left out</text><rect x=\"366\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"418\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">where it is kept</text><path d=\"M470 108 L482 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"418\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">same disk, same</text><text x=\"418\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">credentials</text><rect x=\"484\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"536\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the restore</text><path d=\"M588 108 L600 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1c-wi)\"></path><text x=\"536\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">takes two days</text><text x=\"536\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">when two hours</text><text x=\"536\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">were agreed</text><rect x=\"602\" y=\"86\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"654\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the check</text><text x=\"654\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the only link that</text><text x=\"654\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tests the others</text><path d=\"M12 70 L12 62 L234 62 L234 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"123\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what a green job proves</text><path d=\"M12 206 L12 214 L706 214 L706 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"359\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what a restore proves</text></svg>", "caption": "The chain from the live rows to rows that answer again. A job that exits cleanly says something about the first two links; only a restore that is checked says something about all six."}
```

Every link has a failure that leaves the job green:

- **The copy holds the wrong thing.** The job dumps a database that was renamed last year, or one
  schema out of three, or a file of twenty bytes because the program it piped into succeeded and
  the one that mattered did not. The last section of this lesson does exactly that, on purpose.
- **The copy is right and incomplete.** A logical dump of one database leaves out the roles that
  own its tables and the passwords they log in with. Lesson 2 restores one into a clean server and
  watches it fail on that.
- **The copy cannot be read back.** It was encrypted with a key nobody kept, or compressed by a
  tool the restore machine does not have, or written by a version the restore tools refuse.
- **The copy is gone.** It lived on the same disk, the same account or the same credentials as the
  thing it was protecting, and went with it. Lessons 9 and 10 are about where a copy lives and who
  can delete it.
- **The copy comes back too slowly to matter.** Two days to restore a database the business needs
  back in two hours is a working backup and a failed recovery. Lesson 8 turns that into a number
  somebody agrees to before the incident.

None of these shows up in a job's exit code, and all of them show up in a restore.

## It has happened to people who knew all this

On 31 January 2017 an engineer at GitLab, working late on a replication problem, deleted the data
directory of the production database server instead of the replica's. The company published the
whole incident as it happened. Of the five mechanisms it had for getting data back, **none worked
as intended**: the nightly `pg_dump` had been failing silently because its version did not match
the server's, and the e-mails reporting the failure were being rejected; other copies had never
been configured for that server at all. What saved them was a snapshot taken by hand about six
hours earlier for an unrelated reason, and those six hours of data were lost.

Nobody there was careless about backups in the sense of not having any. They had five. What they
did not have was **a restore that somebody had run recently and watched succeed**, and that is the
only thing that would have found every one of those failures before the night it mattered.

## What this course does about it

The course is built in that order. Lessons 2 to 5 make copies, logical and physical, and the
continuous archive that makes the copy current to the last few seconds. Lessons 6 and 7 restore
them, to a point in time and then as a drill with a stopwatch. Lessons 8 to 10 decide how much loss
and how much downtime is acceptable, and where the copies have to live to survive the people and
programs that might want them gone.

Lessons 11 to 21 are the other half: a second server that is already restored, kept current by
replication, and the machinery that decides when it takes over. Lessons 22 to 24 are what happens
on the day, rehearsed beforehand and written down so that it does not depend on who is awake.

Throughout, **you break things on purpose**, because the course is about what happens when a
database dies, and the way to learn that is to kill one you own. The next section builds the
machine you will do it on.
