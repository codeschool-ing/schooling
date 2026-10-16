---
title: What sorting cost
version: 1
---

**The sorted copy is 484.4 MiB, against the silver layer's 388.8, for the same rows.** Sorting by
one column helps every filter on that column and can hurt the size of every other. The two footers
of 1 January, side by side:

| column | silver layer | sorted by book, 15 row groups |
|---|---|---|
| `event_id` | 257.9 KiB | 279.4 KiB |
| `ts` | 532.3 KiB | 562.5 KiB |
| `visitor_id` | 156.6 KiB | 448.7 KiB |
| `book_id` | 108.4 KiB | 24.5 KiB |

**`book_id` shrank to a quarter**, because sorted values are long runs of the same number and run
length encoding stores a run as one entry. **`visitor_id` nearly tripled**, and that is the row
groups more than the sorting. A dictionary is kept per row group, so fifteen row groups store
fifteen dictionaries, and a visitor who appears in ten of them is spelled out ten times. `event_id`
and `ts` lost their order, so the codec found less to work with.

**So a sort order is a choice about which questions get fast**, paid for in size and in every other
column. The usual choice is the column most queries filter on that is not already a partition:
here, perhaps the book, if the analysts' questions are about books. And the row group size is a
choice between skipping finely and keeping dictionaries whole. 256 KB was chosen here to make a 1 MB
file hold several row groups. On real tables, with files of hundreds of megabytes, the default
128 MB row group already gives a file several, and the problem of this section mostly goes away.
