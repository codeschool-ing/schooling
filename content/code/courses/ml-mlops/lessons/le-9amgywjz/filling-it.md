---
title: Filling it: a backfill and a nightly snapshot
version: 1
---

An empty store answers nothing, so the first job is a **backfill**: computing the features for days
in the past, as they would have been computed on those days. Then, from tonight on, one
**snapshot** a night keeps it current.

```
ana@dev:~/ml$ python featurestore.py backfill 2025-06-01 2026-02-22
39 snapshots, 116285 rows in the offline store
ana@dev:~/ml$ python featurestore.py snapshot 2026-02-28
2026-02-28: 3355 members
ana@dev:~/ml$ ls -lh features.db
-rw-r--r-- 1 ana ana 11M Oct 10 16:44 features.db
```

Thirty-nine Sundays, from 1 June 2025 to 22 February 2026, then tonight, Saturday 28 February. Each
snapshot holds the members active on that day, so the counts grow and shrink with the shop: 3,355
tonight. The offline store holds 116,285 rows from the backfill and 3,355 more from tonight, and `ls` gives the file's
size.

**The backfill is only correct because `features.py` computes everything as of its cutoff.** It
reads purchases up to each Sunday and no further, so a snapshot taken today for last June is the
same snapshot that would have been taken last June. A backfill built from a summary table would fill
the past with today's values, and every training set from it would carry lesson 3's leak.

**Why weekly in the past and nightly from now?** Cost against need. The two cutoffs this course trains and
tests on, 31 August and 30 November 2025, are both Sundays, so weekly history covers them; serving
needs tonight's values. A store that wanted
any day of the past would snapshot daily, at seven times the rows. Choosing the cadence is choosing
how stale a training row may be, and the next section shows what that looks like.
