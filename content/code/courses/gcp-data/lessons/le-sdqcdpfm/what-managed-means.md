---
title: What "managed" takes off your hands, and what it leaves
version: 1
---

**Cloud SQL runs the machine and the engine's housekeeping. It does not run your database.** The
belief that gets a company into trouble is that moving to a managed database means nobody needs to
understand databases any more. What moves to Google is everything underneath the engine and a fixed
list of chores around it. Everything that happens inside the engine stays exactly where it was: with
whoever wrote the schema and the queries.

Quitanda's orders database today is PostgreSQL on one server in a cupboard of the office. Somebody
applies the operating system's updates when they remember, a cron job dumps the database to a disk
next to it every night, and if the server's disk dies, the shop is closed until a new one is bought
and the dump is restored. That is the job Cloud SQL takes, and it is a real job:

| Cloud SQL takes it | it stays yours |
|---|---|
| the machine and its disk, and replacing them when they fail | the schema: tables, keys, types, constraints |
| the operating system, its updates and its security patches | the queries, and the slow ones |
| the engine's minor versions, applied in a weekly window | the indexes, and the missing ones |
| automated daily backups and the log for point-in-time recovery | the flags: memory, logging, timeouts |
| a standby in another zone, when the instance is regional | the number of connections, and what opens them |
| metrics in Cloud Monitoring: CPU, memory, disk, connections | the bill |

**The left column is the work that is the same for every database**, which is why a provider can do
it once for a million customers. The right column is the work that is particular to yours, which is
why no provider can. Cloud Monitoring will tell you that the CPU has been at 95% since Monday. It will
not tell you that a report somebody added on Monday reads the whole `orders` table every minute, and
it will not add the index. `sql-databases` lessons 9 and 10 are that work, and it is the same work on
Cloud SQL as on the server in the cupboard.

## What you give up for it

**There is no shell on the machine.** You never log into a Cloud SQL instance's operating system, you
cannot install a package on it, and you cannot read a file from its disk; the logs come out through
Cloud Logging. **The engine's superuser is not yours either.** On Cloud SQL for PostgreSQL the
`postgres` user that the instance is created with is a member of a role called
`cloudsqlsuperuser`, and Google's documentation is explicit that this is not PostgreSQL's
`SUPERUSER` attribute: it can create databases, roles and the extensions on Cloud SQL's supported
list, and it cannot write a file on the server, load an extension that is not on the list, or run
`ALTER SYSTEM`. The section on flags shows, on a local engine, what that last refusal looks like and
what replaces it.

**The maintenance window is a promise to interrupt you.** Each instance has a weekly hour in which
Google may apply an update, and an update restarts the engine. You choose the day and the hour, you
can declare a deny period of up to 90 days around a busy season, and you cannot have an instance that
is never restarted. Google documents the interruption as short, and much shorter on the Enterprise
Plus edition of the next section; it is still a moment when connections break, and an application
that does not reconnect finds out then. A **major** version upgrade, PostgreSQL 16 to 17, is not
applied for you: you start it, after testing it, because a major version can change how a query
behaves.

## The line, in one place

**Managed moves the operational risk, not the design risk.** A disk that fails, a patch nobody
applied, a backup nobody tested: those were Quitanda's risks and become Google's. A table designed
around the wrong key, a query that reads a million rows to return ten, a connection pool that opens
two thousand connections to an instance sized for four hundred: those were Quitanda's and stay
Quitanda's. Cloud SQL makes the last one more likely, because a bigger instance is one command away,
and a bigger instance is the expensive way to hide a missing index.

**Nothing in this lesson creates a Cloud SQL instance.** There is no emulator for it, and nothing on
the laptop answers to `gcloud sql`. What the lesson does instead is run the engine underneath it,
PostgreSQL 16, on your own machine, where every setting Cloud SQL calls a flag can be seen and
changed. The rest it reads from Google's documentation and from the command line's own reference,
which ships inside `gcloud` and needs no network.
