---
title: Five questions somebody has to be able to answer
version: 1
---

The common picture of a database administrator is somebody who writes clever SQL. That is a
developer's job, and a good one. **The administrator answers for the server the SQL runs on**, and
the work is easiest to describe as five questions about that server that somebody must always be
able to answer, at any hour, with evidence.

**Is it up?** Not "was it up when I last looked", but whether clients can connect now, and whether
somebody would know within minutes if they could not. A server that has been down for an hour
without anybody noticing has two problems, and the second one is worse.

**Is the data safe?** Written to disk when the application was told it was, readable after a power
cut, and not corrupted by a setting somebody relaxed to make a benchmark look good. Lessons 7 and 8
are about what "written" means.

**Can it be restored?** A backup nobody has restored is a hope, and the question is answered only by
having done it, recently, and timed it. This course leaves backups to `db-reliability`, which spends
its first lesson on exactly that sentence; but every lesson here changes what a backup has to
contain, and lesson 4 shows what the files are.

**Who can do what?** Every role, every grant, every password and every network rule that decides who
reaches which rows. The application's account should be able to do what the application does and
nothing else. Lessons 11 to 13 are this question.

**Will it still fit?** Disk, memory, connections, the size of the largest table in six months. Most
outages that are not hardware failures are a limit somebody could have seen coming: a disk that
filled, a connection limit reached on the first busy day, a table that outgrew its maintenance.

## And one more thing that is not a question

Under all five sits **change**. The server is upgraded, its configuration is tuned, its schema
evolves while the application keeps running, and every one of those is a moment when a working
system can stop working. A large part of the job is making change boring: rehearsed, reversible,
written down. Lessons 20, 22 and 23 are about that, and lesson 24 about writing down what you did
when it was not boring at all.
