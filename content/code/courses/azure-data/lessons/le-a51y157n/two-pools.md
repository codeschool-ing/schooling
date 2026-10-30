---
title: A warehouse you run, and one you only ask
version: 1
---

**Synapse Analytics is a workspace that holds two different SQL engines under one name**, and the
difference between them is the difference between owning a warehouse and renting answers. This
section is taught from Microsoft's documentation and was not run: no emulator answers Synapse, and the
rest of the lesson says plainly what stands in for it.

| | dedicated SQL pool | serverless SQL pool |
|---|---|---|
| what it is | a warehouse, its tables stored in its own format | an engine that reads files in the lake |
| you provision | a size in data warehouse units, `DW100c` to `DW30000c` | nothing: every workspace has one, called `Built-in` |
| the data | loaded into the pool's tables | stays in the lake as Parquet, CSV or Delta |
| you pay for | each hour the pool runs, at its size, plus its storage | the data each query processes, per terabyte |
| when nobody asks | still billed, unless you pause it | costs nothing |

## The dedicated pool

**A dedicated SQL pool is a massively parallel warehouse: one control node that plans each query and
compute nodes that run it in pieces.** Its size is a number of data warehouse units, which buys
processor, memory and input and output together; `DW100c` is the smallest, and every step up buys more
compute nodes for the same data. Whatever the size, every table is split into 60 distributions, and
each compute node works on its share of them. The next section is about how rows are assigned to
distributions, because that decides whether the nodes work together or wait for each other.

**A paused pool bills its storage and not its compute**, and pausing is the one setting that matters most
to a warehouse used a few hours a day. Quitanda's nightly report runs for an hour; a pool that runs all
day for it pays for twenty-three hours of nothing. Pausing and resuming take minutes, and a paused pool
answers no queries, so the schedule has to know when the reports run.

## The serverless pool

**The serverless pool reads files where they are**, through `OPENROWSET`, which names the files and
their format, or through external tables defined over a folder. A query over the lake looks like this,
in Synapse's dialect of T-SQL; it is shown and not run:

```sql
SELECT payment, COUNT(*) AS orders, SUM(total_cents) / 100.0 AS reais
FROM OPENROWSET(
    BULK 'https://stquitandalakeprd.dfs.core.windows.net/lake/orders/dt=*/*.parquet',
    FORMAT = 'PARQUET'
) AS orders
GROUP BY payment;
```

**It is billed by the data each query processes**, which the documentation counts as the data read,
plus the data moved between its own steps and anything written, with a minimum of 10 MB per query and
every query rounded up to the next megabyte. There is nothing to provision and nothing to pause, and a
careless query over a large folder is billed for every byte of it. So the layout of the files is the
price list: what a question can skip, it does not pay for. Sections 4 and 5 of this lesson measure that
with a stand-in, and lesson 18 comes back to it with Delta Lake.

**The two are not rivals.** A common shape is the lake as the store of everything, serverless for
exploring it and for questions asked now and then, and a dedicated pool only for the tables that are
queried all day by dashboards that cannot wait. Lesson 17 is Microsoft Fabric, where Microsoft is
taking the same ideas next, under one capacity rather than two engines.
