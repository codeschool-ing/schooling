---
title: Measuring it, exactly and by estimate
version: 1
---

A big table is not a bloated table, and "this table is 117 MB" says nothing about how much of it is
empty. **Measure before deciding anything**, and know which kind of measurement you are reading,
because the cheap one can be wrong in either direction.

## Exact: pgstattuple

`pgstattuple` is an extension that ships with PostgreSQL. Its function of the same name reads every
page of a table and counts what is on it:

<<<measuring>>>

**`free_percent` is the bloat**: more than half of the table's 136,536,064 bytes are free space,
and `tuple_percent` says live rows fill 37% of it. `dead_tuple_count` is 0 because VACUUM has
already been through; on a table with dead versions waiting, that column says how much the next
VACUUM will free.

Exact has a price. **`pgstattuple` reads the whole table**, through the same shared buffers the
application uses. On 117 MB that took about a tenth of a second on the recording machine; on a
table of 500 GB it is a full scan of 500 GB, which belongs at a quiet hour.

`pgstattuple_approx` is the same question asked of the visibility map. It skips every page marked
all-visible and estimates those from the free space map, which is why it answered in a couple of
milliseconds with `scanned_percent` 0. Its free percentage is close; its row count is not, because
the count comes from the planner's statistics, which were taken before the last `DELETE`. **An
estimate is only as current as what it is estimated from.**

## By estimate: arithmetic over the statistics

Monitoring tools that report bloat for every table usually run no extension at all. They take the
planner's statistics, work out how many pages the rows should need, and compare that with how many
pages the table has. A plain version of that query:

<<<estimate>>>

Each row costs a header of 24 bytes, a line pointer of 4, and the average width of each column from
`pg_stats`; a page has 8,192 bytes, less 24 for its own header. For `orders_copy` the arithmetic says
6,077 pages where there are 14,999, which agrees with `pgstattuple` about half the table being spare.

**Now read the `orders` line.** `orders` was loaded once and never updated, so it has no bloat, and
the estimate still says 7,591 pages against 8,334: about a tenth of the table looks wasted. The
missing tenth is padding the formula does not know about, the bytes that align each column to its
boundary. Better queries correct for more of it, and none of them is exact. **Use the estimate to
choose which tables to look at, and `pgstattuple` to decide.**
