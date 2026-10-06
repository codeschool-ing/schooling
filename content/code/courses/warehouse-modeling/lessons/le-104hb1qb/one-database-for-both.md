---
title: Why not one database for both
version: 1
---

The obvious objection is that the report worked. It took 1.6 seconds, it gave the right answer,
and it did not need a second database. For a shop this size, on a quiet afternoon, that is true,
and it is the strongest version of the case for not building a warehouse.

**The answer is in the conditions, not in the number.** The report ran alone. In production it
would run beside the tills, and the two compete for the same three things:

- **Memory.** The report pulled 103 MB of pages through PostgreSQL's shared memory. Those pages
  displace the ones the tills were using, and the next lookup that misses has to go to disk.
- **Disk.** The 119 MB of temporary files were written while somebody at Paulista was waiting for
  a receipt.
- **Processors.** One report is one process at full speed for its whole run. Ten managers opening a
  dashboard at nine on Monday morning are ten.

None of that is fatal at 895,000 lines. **It grows with the history, and the tills do not.** A till
writes the same four rows in year five as in year one; the report reads five years instead of
two. The one workload gets heavier every month while the other stays still, which is why this
argument is usually lost slowly rather than all at once.

Two more reasons have nothing to do with speed:

- **The model fights the question.** The report needed six tables and a `coalesce` to cope with a
  category tree that is two levels deep in some places and three in others. Every person who
  writes a report has to know that, and the one who does not gets a wrong total that looks right.
- **The history is not there.** The operational database keeps the current state, so some
  questions about the past cannot be answered from it at any speed. That is the next section.

**The case for one database is strongest when the data is small, the questions are few and nobody
asks about the past.** Lesson 7 comes back to it with a number for "small".
