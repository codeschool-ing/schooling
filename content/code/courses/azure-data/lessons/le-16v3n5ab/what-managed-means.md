---
title: What the database service takes, and what it leaves
version: 1
---

**Azure SQL Database runs the machine, the engine and its housekeeping. It does not run your
database.** The belief that gets a company into trouble is that moving to a managed database means
nobody needs to understand databases any more. What moves to Microsoft is everything underneath the
engine and a fixed list of chores around it. Everything that happens inside the engine stays where it
was: with whoever wrote the schema and the queries.

**This section is taught from Microsoft's documentation for Azure SQL Database, and nothing in it was
run**, because the service is a part of Azure no emulator answers. The next section runs the engine
underneath it.

Quitanda's orders database today is SQL Server on one server in a cupboard of the office. Somebody
applies the operating system's updates when they remember, a job dumps the database to a disk next to
it every night, and if the server's disk dies the shop is closed until a new one is bought and the
dump is restored. That is the job the service takes, and it is a real job:

| Azure SQL Database takes it | it stays yours |
|---|---|
| the hardware, and replacing it when it fails | the schema: tables, keys, types, constraints |
| the operating system and the engine, patched and upgraded | the queries, and the slow ones |
| backups, and restoring to any point in the retention period | the indexes, and the missing ones |
| high availability and the failover, inside the price | how much compute to buy, and in which model |
| metrics and alerts on CPU, IO and storage | the number of connections, and what opens them |

**The left column is the work that is the same for every database**, which is why a provider can do
it once for a million customers. The right column is particular to yours, which is why no provider
can. The service will show you, in its metrics, that the database has been at its limit since Monday.
It will not tell you that a report somebody added on Monday reads the whole `orders` table every
minute, and it will not add the index. `sql-databases` lessons 9 and 10 are that work, and it is the
same work here as in the cupboard.

## A server that is not a server

**What Azure calls a logical server is a name and a set of settings, not a machine.** It answers at
`<name>.database.windows.net`, holds the administrator login, the firewall rules and the auditing, and
groups databases that may each run on different hardware in the same region. You never log into it,
and nothing in it is shared between its databases except those settings. Each database is bought on
its own, in one of the purchasing models of this lesson, or shares a pool with others, and that is
what Azure bills.

**The engine is always the newest one.** Azure SQL Database has no version to choose and no upgrade
to schedule: Microsoft moves it forward, and features reach it before they reach the boxed SQL
Server. Patches are applied by the service, in a window you can influence and not avoid, and a
well-written application sees a reconnect and nothing else, which is why the documentation insists on
retry logic in every client.

**Backups are automatic and the restore is to a point in time**, any second inside a retention period
of 1 to 35 days, seven by default. A restore creates a new database beside the old one, rather than
overwriting it. Longer retention, weekly or monthly copies kept for years, is a separate policy.

## What you give up for it

**There is no instance.** One database is the whole of what you rent, so everything that belongs to an
instance of SQL Server is missing or replaced: the SQL Agent that runs jobs on a schedule, queries
that name a second database on the same server, the files on the machine's disk. Most applications
never notice. A company whose nightly jobs run in SQL Agent and whose reports join two databases
notices on the first day, and lesson 9 is the service built for that company.

**Managed moves the operational risk, not the design risk.** A disk that fails, a patch nobody
applied, a backup nobody tested: those were Quitanda's risks and become Microsoft's. A query that
reads a hundred thousand rows to return fifteen stays Quitanda's, and the next section shows one.
