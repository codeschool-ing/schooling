---
title: When to leave it alone
version: 1
---

A rebuilt table looks like a win on a graph of disk usage, and for a table that is updated all day
it is a win that undoes itself. **A table with steady traffic settles at a size of its own**, larger
than its rows, and stays there. The free space is where each day's updates land. Take it away and
the next updates have to grow the file again to find room.

The compact copy from the previous section shows it. Update a fifth of its rows, vacuum, and look;
then do it twice more, with a different fifth each time:

<<<steady>>>

The first round grew the table from 59 MB to 70 MB, because a compact table has nowhere to put new
versions except the end. **The second round did not grow it at all**: VACUUM had freed the first
round's old versions, and the second round's new versions went into that space. The third added a
megabyte. That is the shape of a healthy table under load, and 70 MB is this table's working size
for this traffic. Rebuilding it to 59 MB again would buy back 11 MB until the next batch of updates.

The indexes moved further, from 34 MB to 63 MB in the first round, and they stayed there too. Their
compact size after a rebuild was only true until the first wave of updates.

So the useful question is not "how much free space is there" but **whether the free space is larger
than the traffic will ever use**. Some cases where it is:

- a one-off: a backfill, a mass correction or a purge of old rows, like the update of every row at
  the start of this lesson. The space it left will not be reused at the rate it was made;
- the disk is running out and the space is needed elsewhere now;
- sequential scans of the table are a problem, and `pgstattuple` says most of what they read is
  empty.

And some where it is not: a table that grows back to the same size within days of a rebuild, a
free percentage that is steady from week to week, a table nobody scans in full. For a table with
many updates you can even ask for more free space on purpose. `ALTER TABLE ... SET (fillfactor =
90)` makes inserts leave a tenth of each page empty, so that an update finds room on the same page
and can be HOT, with no new index entries at all.

## Putting shop back

The copy, and the two extensions in `shop`, were for this lesson. The package stays installed;
removing it is not needed.

<<<cleanup>>>
