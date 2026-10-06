---
title: Where the line blurs
version: 1
---

The split is not absolute, and three things you will meet in practice sit across it. Each solves
part of the problem and leaves the rest, which is why none of them replaced the warehouse.

## A read replica

PostgreSQL can keep a second copy of the database, a **replica**, that replays every change the
primary makes, a fraction of a second behind. Reports run on the replica and the tills never feel
them.

**It solves the competition for memory, disk and processors** from section 07, completely. It
solves nothing else. The replica has the same normalised schema, so the report still needs six
tables and a `coalesce`. It has the same current-state rows, so customer 2123 is still in Paraná
for every order they ever placed. A replica is the right first step for a small shop whose reports
are slowing the tills, and the wrong last one.

## Change data capture

Instead of copying whole tables every night, a tool reads the database's own log of changes, the
write-ahead log in PostgreSQL, and streams each insert, update and delete somewhere else as it
happens. This is **change data capture**, CDC.

It changes *how* the warehouse is loaded: continuously, and with every intermediate state of a row,
including the old city before the update. That makes it the best source a warehouse can have for
history. It does not change *what* the warehouse is, and `pipelines-etl` is where it is built.

## One engine for both

Some databases claim to do both workloads at once: **HTAP**, hybrid transactional and analytical
processing. Typically they keep the data twice inside one product, once by row for the
transactions and once by column for the analysis, and keep the two in step themselves. SingleStore
and TiDB are built that way, and the columnar copy that lesson 8 measures is the idea underneath.

**What HTAP removes is the pipeline between two databases. What it cannot remove is the model.**
A customer who moved is still one row, and a report still has to know what revenue means. The
dimensional model in lessons 2 to 5 is a decision about *meaning*, and it is needed wherever the
data physically sits.
