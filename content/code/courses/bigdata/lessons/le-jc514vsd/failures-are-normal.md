---
title: On a large cluster, something is always broken
version: 1
---

**On one computer, a hardware failure is an event. On a thousand computers, it is the weather.**
That single change in arithmetic is why every system in this course is built the way it is, and it
is worth doing the sum once.

Suppose a machine fails, on average, once in a thousand days: a disk, a power supply, a memory
module, a kernel that hangs. That is less than once in two and a half years, and a team running
one server would call it reliable. Now run a thousand of them:

| machines | failures a day, on average | a 4-hour job sees a failure |
|---|---|---|
| 1 | 0.001 | about one run in 6,000 |
| 100 | 0.1 | about one run in 60 |
| 1,000 | 1 | about one run in 6 |
| 10,000 | 10 | most runs, often more than once |

The figure of one failure in a thousand days is an example chosen for round numbers, not a
measurement of any hardware; real rates depend on the parts and their age. The shape of the table
does not depend on it. **Multiply a small chance by enough machines and it stops being small.**

The column on the right is the one that matters. If a job has to be restarted from the beginning
every time any machine fails, then on a thousand machines one four-hour job in six is lost, and on
ten thousand machines a four-hour job cannot finish at all. So a system meant for many machines has
to do three things that a program on one machine never thinks about:

1. **Notice** that a machine is gone, quickly, without being told.
2. **Know what was lost**: which pieces of work were running there, and which results lived only
   on that machine.
3. **Redo only that**, somewhere else, and carry on.

The next three sections kill one process each, with `kill -9`, which gives it no chance to say
goodbye: an executor, a worker, and the driver. Each recovers differently, and one does not
recover at all.
