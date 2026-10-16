---
title: What "managed" takes off your hands, and what it leaves
version: 1
---

**RDS runs the machine and the engine's housekeeping. It does not run your database.** The common
belief, the one that gets a company into trouble, is that moving to a managed database means nobody
needs to understand databases any more. What moves to AWS is everything underneath the engine and a
fixed list of chores around it. Everything that happens inside the engine stays exactly where it was:
with whoever wrote the schema and the queries.

Quitanda's orders database today is PostgreSQL on one server in a cupboard of the office. Somebody
applies the operating system's updates when they remember, a cron job dumps the database to a disk
next to it every night, and if the server's disk dies, the shop is closed until a new one is bought
and the dump is restored. That is the job RDS takes, and it is a real job:

| RDS takes it | it stays yours |
|---|---|
| the hardware, and replacing it when it fails | the schema: tables, keys, types, constraints |
| the operating system, its updates and its security patches | the queries, and the slow ones |
| installing the engine, and minor-version upgrades in a weekly window | the indexes, and the missing ones |
| automated backups, kept for up to 35 days | the parameters: memory, logging, timeouts |
| failover to a standby in another zone, when you pay for one | the number of connections, and what opens them |
| metrics: CPU, memory, storage, connections | the bill |

**The left column is the work that is the same for every database**, which is why a provider can do it
once for a million customers. The right column is the work that is particular to yours, which is why
no provider can. RDS will tell you, through its metrics, that the CPU has been at 95% since Monday. It
will not tell you that a report someone added on Monday reads the whole `orders` table every minute,
and it will not add the index. `sql-databases` lessons 9 and 10 are that work, and it is the same work
on RDS as on the server in the cupboard.

## What you give up for it

**There is no shell on the machine.** You never log into an RDS instance's operating system, you
cannot install a package on it, and you cannot read a file from its disk; the logs come out through
the API. The engine's own superuser is not yours either. In PostgreSQL, the master user is a member
of a role called `rds_superuser`, which can do nearly everything an administrator does inside the
database and nothing outside it: no extension that is not on RDS's list, no file written to the server.
Most applications never notice. An application that relied on a custom extension compiled on the old
server notices on the first day.

**The maintenance window is a promise to interrupt you.** Each instance has a weekly half-hour in which
RDS may apply a pending patch, and some patches restart the engine. You choose when the window falls,
and you can see what is pending; you cannot have an instance that is never restarted. A major version
upgrade, PostgreSQL 16 to 17, is never applied for you while the version is supported. You start it,
after testing it, because a major version can change how a query behaves.

## The line, in one place

**Managed moves the operational risk, not the design risk.** A disk that fails, a patch nobody applied,
a backup nobody tested: those were Quitanda's risks and become AWS's. A table designed around the wrong
key, a query that reads a million rows to return ten, a connection pool that opens two thousand
connections to an instance sized for four hundred: those were Quitanda's and stay Quitanda's, and RDS
makes the last one more likely, because creating a bigger instance is one command, and a bigger
instance is the expensive way to hide a missing index.
