---
title: What to cache, and when to let go
version: 1
---

**Cache what is used more than once, after the work that makes it expensive, and with only the
columns that will be read.** Each part of that sentence comes from section 02's numbers.

- **More than once.** A cache is a copy, and the first use pays for it. A result used once is
  only slower for being cached.
- **After the expensive work.** Caching the raw clicks saves a read of the files, which Spark does
  quickly. Caching the result of a join, a window or a heavy filter saves the join, the window or
  the filter, each time.
- **Only the columns that will be read.** Three columns took 51.4 MiB where seven took 284.7. A
  `select` before the `cache` leaves memory for the work, and for other caches.

**A cache is lazy.** `cache()` and `persist()` mark a DataFrame and return at once; the first action
that computes it fills the copy. A program that caches a DataFrame and then only ever uses a filtered
version of it caches nothing useful, because the filtered version is a different plan.

**A cache is kept until the application ends, or until it is pushed out.** Storage memory is shared
with execution, lesson 7's unified region. When a running task needs room, Spark evicts cached
partitions, the least recently used first, and a cache that was there a minute ago may be partly
gone, with no error. `df.unpersist()` lets go of a cache as soon as it is no longer needed, which is
the polite thing to do in a long program and the necessary one in a loop.

In SQL the same thing is a statement, and unlike `cache()` it is eager unless told otherwise:

```sql
CACHE TABLE purchases AS SELECT * FROM clicks WHERE kind = 'purchase';
CACHE LAZY TABLE purchases AS SELECT * FROM clicks WHERE kind = 'purchase';
UNCACHE TABLE purchases;
```

`CACHE TABLE` fills the copy before it returns. `CACHE LAZY TABLE` waits for the first query, like
`cache()`. Either way the cached table is visible to every query of the application, by name.
