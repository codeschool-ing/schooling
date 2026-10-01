---
title: What goes wrong by hand
version: 1
---

The failures in the last section are not bad luck. **They are the three ways a change made by
hand goes wrong**, and they have names:

- **A wrong value that is valid.** `192.0.12.0/24` parses, so nothing refuses it. The router
  checks that a prefix list is well formed and cannot check that it is the one you were asked for.
- **An omission.** `edge2` was never touched. Nothing on `edge2` says a change was due, and
  nothing on the other two says it happened elsewhere.
- **Drift.** Once the three routers differ, every later change is made against three different
  starting points, and the difference grows. Nobody decided that `edge1` should be special; it
  became special one keystroke at a time.

**The common belief is that care fixes this**: slow down, read twice, use a checklist. Care
lowers the rate and never reaches zero, and the rate is multiplied by the number of devices and
the number of changes. A careful person making one typo in a hundred commands, on a network of a
hundred routers, types one mistake per change on average, and ships it with every change.

What automation changes is **where the mistake can happen**. A script types the line the same
way every time, so a typo in the script is a typo everywhere, which is worse in one way and far
better in another. It is found once, on the first router, by whoever reads the output, and it is
fixed in one place. A typo typed by hand on the fortieth router is found when something breaks.

**Automation does not remove human error. It moves it to where it can be reviewed**: a file that
a colleague reads before it runs, and a test that runs before it reaches a device. Lessons 13 and
14 build both.
