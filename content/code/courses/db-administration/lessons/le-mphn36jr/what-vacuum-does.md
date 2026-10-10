---
title: What VACUUM does, and what it does not
version: 1
---

The name suggests a table that gets smaller. **A plain `VACUUM` does not shrink the file**, apart
from empty pages at its very end, which lesson 15 measures. What it does is three jobs, and each one
is something no other part of the server does.

**It makes dead space reusable.** VACUUM reads the pages that have changed, finds the versions no
transaction can see, removes the index entries that point at them and records the freed room in the
table's **free space map**. The next `INSERT` or `UPDATE` that needs room finds it there instead of
growing the file.

**It keeps the visibility map.** One bit per page says that every row on the page is visible to
every transaction. A page with that bit set can be skipped by the next VACUUM, and an index-only
scan can trust the index without visiting the table. A second bit says every row on the page is
also frozen, which the third job explains.

**It freezes old rows**, marking them as visible to everybody so their `xmin` never has to be
compared with anything again. The wraparound section, two sections on, is why that matters.

`pg_visibility` is another extension that ships with PostgreSQL. It counts both bits:

<<<what-vacuum-does 1-5>>>

The `UPDATE` took 836 pages out of the visibility map: the pages it removed rows from and the pages
it wrote the new versions into. VACUUM put them back. **The size did not move**: 68 MB before and
after, because the space the 50,000 dead versions held is now free space inside the file, waiting
for the next rows.

The 415 frozen pages are a version 16 habit. When VACUUM is already writing a page out in full to
the write-ahead log, it freezes the page while it is there, because the extra work is nearly free.
Everything else waits until its rows are old enough, or until somebody asks:

<<<what-vacuum-does 6-9>>>

**`relfrozenxid` is the oldest transaction id that can still appear unfrozen in the table**. Before
the `FREEZE` it was 782, the transaction that loaded the copy. After it, every page is frozen and
the number has moved up to the present, with an age of 0. Autovacuum keeps that age within bounds by
itself; how far it may drift is the wraparound section's subject.

**A plain VACUUM does not get in anybody's way.** It takes a lock that conflicts only with another
VACUUM and with changes to the table's structure, so reads and writes carry on while it runs.
`VACUUM FULL` is a different command that rewrites the table under an exclusive lock, and lesson 15
shows what that costs. The other thing `VACUUM ANALYZE` did when the copy was made, updating the
planner's statistics, belongs to `ANALYZE`, and lesson 16 is about it.
