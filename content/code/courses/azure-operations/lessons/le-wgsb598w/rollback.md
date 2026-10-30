---
title: Rolling back, and the one thing a swap cannot undo
version: 1
---

**Rolling back a slot deployment is the same swap again.** After the swap, the staging slot holds the
previous version, already warm. If production misbehaves, swapping back restores it in the time a swap
takes, without rebuilding anything. That is the reason to keep the old version in staging until the new
one has run for a while, rather than deploying the next build over it immediately.

What decides how fast that happens is not the swap; it is noticing. The shop's rule is written in
terms of what lesson 14 will measure: if the error rate of `POST /checkout` in the fifteen minutes after
a swap is above the objective, swap back first and investigate second. A rollback that waits for a
diagnosis is a rollback that waits while customers fail.

## What it does not undo

**A swap exchanges code and configuration. It does not touch the data.** If release 42 renamed a
column, release 41, swapped back in, queries a column that no longer exists, and the rollback that took
thirty seconds is now an outage of its own. The same is true of a message format, a cache key, a file
written to storage in a new shape: anything the new version wrote that the old version cannot read.

The answer is not a better rollback; it is changes that make rollback safe. **Expand, then contract.**
Each change to shared data is split so that every release can run against the data the release before
it left:

```sql
-- release 42: expand. Old code ignores the column; new code writes both.
ALTER TABLE orders ADD delivery_window varchar(20) NULL;

-- release 43, a week later: contract. Only after nothing reads delivery_slot.
ALTER TABLE orders DROP COLUMN delivery_slot;
```

Release 42 adds the new column and writes both. Swapping back to 41 is safe, because 41 never knew
about `delivery_window` and still finds `delivery_slot`. Only when 42 has run long enough that nobody
will swap back does release 43 remove the old column. The cost is a second release and a week of
writing two columns. The benefit is that **every swap in either direction is safe**, which is what
makes the button worth having.

None of this was run in the lab: there is no App Service and no database here. The SQL is plain
standard SQL, and `azure-data` covers Azure SQL itself.
