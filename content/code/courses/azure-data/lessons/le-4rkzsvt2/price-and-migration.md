---
title: What it costs, how a company gets there, and when it is the answer
version: 1
---

**A Managed Instance is billed like lesson 8's vCore model, at the size of an instance**: vCores by the
hour, storage by the GB reserved, backups past an allowance, and the licence unless the Hybrid Benefit
removes it. There is no serverless and no DTU. What makes it a different decision is the floor: the
smallest instance is several vCores running all month, where the smallest database is a few DTUs.

**This section is taught from Microsoft's documentation, and nothing in it was run.** The sums use the
illustrative price of lesson 8, 0.25 USD per vCore-hour, and say so.

## The shape of the bill

Quitanda's instance of the previous section, 8 vCores in General Purpose, is 8 × 0.25 × 730 = 1,460.00
a month in compute at that illustrative price, before storage, whether one database is busy in it or
twenty. Two things move that number down, and both are documented:

- **instance pools**, which let several small instances share the machines of one pool, so that a
  company with many small workloads does not pay the floor once per instance;
- **stopping a General Purpose instance**, which stops the compute bill while the storage, and its
  bill, stay; useful for an instance used in office hours or for tests, and as with lesson 8's pause,
  nothing answers until it is started again.

**The licence is the line that decides most moves.** With `LicenseIncluded`, the hourly price carries
Microsoft's licence for SQL Server; with `BasePrice`, the company brings licences it already owns with
Software Assurance and pays only for the compute. A company leaving a cupboard of licensed SQL Servers
has usually paid for those licences already, and the Hybrid Benefit is how that payment keeps counting.

## Getting there

A database in a cupboard reaches Managed Instance by one of three roads, each documented by Microsoft:

| road | how it works | the cut-over |
|---|---|---|
| backup and restore | `BACKUP DATABASE` on the old server, the `.bak` copied to Blob Storage, `RESTORE ... FROM URL` on the instance | the old database stops taking writes for the whole copy and restore |
| Log Replay Service | full, differential and log backups dropped into a blob container, replayed on the instance as they arrive | a short one, after the last log backup is applied |
| the Managed Instance link | a distributed availability group from the old SQL Server to the instance, replicating continuously | a short one, and the link can be kept as a copy for reading in Azure |

**All three move the database with its jobs, its logins and its three-part names working**, which is
the reason to choose an instance: the application moves, and nothing in it is rewritten that day. The
Azure Database Migration Service wraps the first two in a guided process. The copy into a blob
container is the step this course has already practised, in lesson 2.

## When it is the answer

**Managed Instance is the answer when the database depends on its instance**: SQL Agent jobs, queries
across databases, linked servers, CLR, Service Broker, Database Mail, or a vendor's application that
was certified against SQL Server and nothing else. **Azure SQL Database is the answer for new work**,
and for databases that use none of those, because its floor is lower, it scales one database at a time
and it offers serverless and pools. **SQL Server on a virtual machine of your own** is what remains
when even an instance is not enough: a feature Managed Instance does not have, or a need to reach the
operating system, at the price of patching it yourself again.

Quitanda's orders database used SQL Agent for the nightly totals and a three-part name for the support
screen. Both could be rewritten, the job as an elastic job and the deliveries moved into one database,
and its single database would then be cheaper on Azure SQL Database. Whether that rewrite is worth it
is the decision, and its price is lesson 8's bill against this one.
