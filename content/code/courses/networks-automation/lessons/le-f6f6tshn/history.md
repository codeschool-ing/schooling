---
title: A history, not a pile of copies
version: 1
---

The second run, a minute later, finds nothing to do:

```
ana@ctl:~$ cd net && python backup.py
no change since the last backup
```

**No commit, no file with a new date, nothing.** That matters more than it looks. A backup job that
wrote a dated copy every night, `edge1-2026-10-01.conf` next to `edge1-2026-09-30.conf`, would
produce three hundred and sixty-five files a year per router, nearly all of them identical, and
finding the night something changed would mean comparing them pairwise. In Git, the night
something changed is a commit, and the nights nothing did are absent.

Git also brings the tools that work on any history: `git log` lists the changes, `git log -p
edge1.conf` shows every change to one router, `git diff` compares any two points, and `git show`
recovers any file as it was at any commit. None of that was written for this lesson; it is what
choosing Git as the store buys.

The commit message is built from the files that changed, `backup: edge1`, so `git log --oneline` is
already a readable summary of which routers changed when. Run from a scheduler, the author and the
date are the job's own; lesson 14 runs it from a pipeline, where each run also leaves a log.
