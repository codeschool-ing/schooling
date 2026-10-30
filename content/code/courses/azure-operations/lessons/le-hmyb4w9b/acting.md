---
title: Acting on it, with the owner
version: 1
---

**Finding is the easy half. Acting safely has four steps, and the shop learned the second one on a
Thursday.**

1. **Find the owner.** From the tag, from the activity log's `Caller` of the creating deployment (lesson
   21), or by asking in the team channel. Three of the four idle resources had no `team` tag; `rg-test-ana`
   is a clue, and the activity log confirms who created it.
2. **Check against the workload's calendar, not only its last fortnight.** `vm-reports` is idle for 28
   days and essential for 2. Lesson 15's incident was a database rightsized by hand on a quiet-looking
   afternoon that was not quiet. A rightsizing change goes through the same review, the same pipeline and
   the same canary as any other change; the size goes into the Bicep, not into the portal.
3. **Prefer the reversible action.** Stop a VM before deleting it; snapshot a disk before deleting it;
   schedule `vm-reports` to start on the 28th and stop on the 2nd instead of deleting it. A deallocated VM
   stops paying for compute and keeps its disks.
4. **Write down what was saved**, with the before and after from the cost export of lesson 24. A
   rightsizing that nobody measured is a rumour, and the next one is easier to argue for when the last one
   has a number.

For the shop, the decisions came out as: snapshot and delete the two disks, delete `pip-test` and
`asp-shop-old` after their owners agreed, resize `vm-shop-batch` from eight vCPUs to two through the
pipeline, and put `vm-reports` on a start-and-stop schedule with Hybrid Benefit switched on, from lesson 22.
None of these changes was made, because none of these resources exists outside this course.
