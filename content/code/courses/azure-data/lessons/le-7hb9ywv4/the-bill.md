---
title: The bill: runs, DIU-hours and the hours of a runtime
version: 1
---

**Data Factory's bill has no line for the factory itself; it charges for what the factory does.**
The meters below come from Microsoft's documentation, and the prices that follow them are
**illustrative**, round numbers to do the arithmetic with and not Azure's prices; lesson 1's price
sheet gives the real ones for `brazilsouth`. Nothing in this section was billed.

## The meters

| meter | what it counts |
|---|---|
| orchestration | activity runs, trigger runs and debug runs, per thousand |
| data movement | DIU-hours of copy activities on the Azure runtime |
| pipeline activities | hours of activities such as `Lookup` and `Get Metadata` that run on a runtime |
| external activities | hours of activities that wait while another service works: a stored procedure, a Databricks notebook |
| data flows | vCore-hours of the Spark clusters that mapping data flows run on, lesson 20's subject |
| self-hosted | the same activities at other prices, and the machine, which is yours |
| Azure-SSIS | node-hours while the SSIS runtime is started |

**The external activities line is the one that surprises.** An activity that starts a Databricks job
and waits an hour for it is billed for the hour, a small amount per hour, on top of what Databricks
charges for running it. A pipeline whose only work is to wait for other services pays for the waiting.

## Quitanda's month, at illustrative prices

The nightly load runs once a day: a trigger run, a copy, a stored procedure that updates a summary
table, and a web activity that posts to the team's channel when it finishes. Four activity runs and a
trigger run a night, 31 nights:

- **orchestration**: 5 × 31 = 155 runs. At an illustrative 1.00 USD per thousand runs, 0.16 USD;
- **data movement**: one copy of a day's export, say on 4 DIUs for 2 minutes, is 4 × 2 / 60 = 0.13
  DIU-hours a night, 4.13 a month. At an illustrative 0.25 USD per DIU-hour, 1.03 USD;
- **external activity**: the stored procedure waits 3 minutes a night, 1.55 hours a month. At an
  illustrative 0.0003 USD per hour, 0.0005 USD: next to nothing, because the meter is for waiting
  and the waiting was short.

**About 1.19 USD a month at these numbers, for a pipeline that runs every night.** The arithmetic is
there to show which line grows. Orchestration grows with the number of runs, so a pipeline triggered
every minute instead of every night costs 1,440 times as much in that line, and a `ForEach` over a
thousand files is a thousand activity runs each time. Data movement grows with the DIUs and the
minutes, so a copy that is slow because its source is slow pays for DIUs that waited. The rest is
small until a data flow or an external service enters the night, and then that service's bill is the
one to read.

## What the arithmetic leaves out

**The machine of a self-hosted runtime, which is billed as a machine**: a Windows server running all
month for a copy that takes four minutes a night. And the services the pipeline calls, which each
bill on their own: the storage account's operations from lesson 7 for every file the copy reads and
writes, the database's own compute while the stored procedure runs, Databricks' DBUs while its job
runs. Data Factory's own line is usually the smallest on the invoice of a data platform, and the
orchestration decides how large the others are.
