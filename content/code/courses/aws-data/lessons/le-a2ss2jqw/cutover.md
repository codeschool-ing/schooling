---
title: The cutover, and what the migration costs
version: 1
---

**The cutover is the minute the applications stop writing to the old database and start writing to
the new one**, and everything before it exists to make that minute short and boring. With a
full-load-and-cdc task running, the target is seconds behind the source, so the downtime is not the
hours of the copy but the time it takes to stop the writers, let the last changes cross, check, and
start the writers against the target.

**The order is the part people get wrong**, and getting it wrong in either direction loses data:
switch the applications before the last changes have crossed and those changes are lost, let the
applications write to both and the two databases disagree.

1. **Run the task until it is quiet.** The full load finished, validation reports every table as
   validated, and the CDC latency DMS reports is a few seconds.
2. **Stop the writers on the source.** Put the shop into maintenance, or revoke the application
   user's right to write, so that nothing new reaches the old database.
3. **Wait for the last changes to cross**, until the latency reaches zero and the counts and totals
   of the important tables agree between the two sides.
4. **Point the applications at the target** and start them.
5. **Stop the task, and keep the source read-only** for as long as a rollback might be wanted. The
   old database is the backup of the first day.
6. **Drop the replication slot on the source**, the previous section's warning, once the task is
   gone for good. A slot left behind after a cutover is the classic way to fill a disk a month later.

For Quitanda's first project the target is the lake rather than a new database, so there is no
application to move: the task simply runs, and the cutover is the day the reports stop reading the
old PostgreSQL. The same order applies to the day the shop itself moves to RDS, lesson 6's subject,
with a database endpoint as the target instead of S3.

## What it costs

```
ana@laptop:~/aws$ python3 prices.py dms
AWS public price list, sa-east-1, USD, excluding tax

DMS, USD per hour
  replication instance dms.t3.medium                    0.15100  hour
  replication instance dms.c5.large                     0.31000  hour
  replication instance dms.r6i.large                    0.56000  hour
  Serverless, per DCU-hour                              0.18471  DCU-hour
```

**A replication instance is billed for every hour it exists, like an MWAA environment in lesson 25,
and unlike one it is meant to be temporary.** A migration that runs for two weeks on a
`dms.c5.large` costs 0.31000 × 24 × 14 = 104.16 USD, and the same instance forgotten for a year after
the cutover costs 0.31000 × 8760 = 2715.60. A permanent feed into the lake, which is what Quitanda's
first task is, pays the instance every month: 0.31000 × 730 = 226.30 on a `dms.c5.large`, or
0.15100 × 730 = 110.23 on a `dms.t3.medium` if that is enough for the rate of change.

**Serverless prices the capacity used instead of the instance owned.** At 0.18471 a DCU-hour, a feed
that sits at 2 DCUs all month costs 2 × 0.18471 × 730 = 269.68, more than the `dms.c5.large` for the
same month. A migration that needs 16 DCUs for the two days of its full load and 2 for the rest of
the fortnight costs 16 × 0.18471 × 48 + 2 × 0.18471 × 288 = 141.86 + 106.39 = 248.25. Serverless wins
when the load is uneven and nobody knows its size in advance; an instance wins when the load is
steady and somebody has measured it. Neither line includes the source's side: the network path from
the rack, and the extra reads validation makes.

**The cost that matters most is not on the sheet.** A migration whose cutover goes wrong costs the
shop's orders for however long it takes to notice, and the steps above, with validation turned on,
are cheaper than any instance class.
