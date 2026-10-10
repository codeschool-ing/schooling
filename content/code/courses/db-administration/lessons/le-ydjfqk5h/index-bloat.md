---
title: Index bloat, read off the leaf pages
version: 1
---

An index bloats for a reason of its own. **Every non-HOT `UPDATE` adds a new entry to every index
on the table**, pointing at the new version, and VACUUM later removes the old entry. A B-tree page
that loses entries keeps its place in the tree half empty, and a page is only recycled once it is
entirely empty. So an index that once held two entries per row keeps the pages it grew to hold them.
(HOT, heap-only tuple, is the case where the new version fits on the same page and no indexed
column changed; then the indexes are not touched at all. Updating every row of a full table leaves
no room for that.)

`pgstatindex`, from the same extension, reads a B-tree and reports on its leaf pages, the bottom
level where the entries live. Here are the copy's three indexes beside the three of `orders`, which
hold the same kind of rows and have never seen an `UPDATE`:

<<<index-bloat>>>

**`avg_leaf_density` is how full the leaf pages are on average.** An index whose keys arrive in
ascending order fills each leaf to 90%, the default fill factor for an index, and moves on to the
next; `orders_pkey` grew that way while `shop.sql` inserted ids 1 to a million, and it is exactly
at 90. The copy's primary key is at 45%: twice the pages for fewer rows, 43 MB against 21 MB. The
other two indexes of the copy are as thin.

The other two indexes of `orders` show why a fixed target is the wrong yardstick. Their keys
arrived out of order during the load, and an insert into the middle of a full leaf splits it into
two half-full pages that then fill up again, so they settle lower than 90 without one dead entry:
87.53 and 78.11. **Compare an index with the same index unbloated**, as this query does with the
originals, rather than with a number from a book.

`leaf_fragmentation` is the share of leaf pages whose next page in key order is not the next page in
the file. Those mid-leaf splits are what put `orders_customer_id` near 50 with no bloat at all. It
matters to a range scan reading many leaves on a spinning disk, and much less on an SSD. **Density
is the number to act on**; fragmentation is a detail.

Fixing an index on its own is `REINDEX`, and doing it without blocking writes is
`REINDEX CONCURRENTLY`; both are lesson 17's subject. The two fixes in the next section rebuild the
indexes as a side effect of rebuilding the table.
