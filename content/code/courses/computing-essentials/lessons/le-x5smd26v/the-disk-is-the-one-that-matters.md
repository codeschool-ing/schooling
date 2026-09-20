---
title: The disk, which is the only part that takes your work with it
version: 1
---

Every other component in this lesson can be replaced and you lose nothing but money. The disk is
different, and that difference decides how to behave the moment it is suspected.

## Two kinds, two ways of failing

**A spinning hard disk is a machine**: a platter turning, a head on an arm moving across it. It
fails mechanically, it gets slower first, and **it usually makes a noise** — a rhythmic click, a
tick, a grinding. That noise is the head failing to find its place and retrying.

**A solid-state disk has no moving parts.** It is silent, it does not slow down gradually in the
same way, and it tends to fail more suddenly — often going read-only, or disappearing between one
start and the next. It is more reliable in general and less polite about the end.

## The symptoms, in the order they usually arrive

- **Files that take far too long to open**, one file in particular, over and over. The disk is
  retrying a region it cannot read.
- **The whole machine freezing for seconds at a time**, with everything else fine — a pause, then
  normal. That is the machine waiting for a read.
- **A file that will not copy**, with an error part-way through, when the same file copied fine
  last month.
- **A message about the file system being repaired** at startup, more than once.
- **The disk not being found at all**, on some starts and not others.

## SMART, which is the disk's own opinion

Disks keep their own health counters — reallocated sectors, pending sectors, read errors, hours
powered on — and report them under the name **SMART**. Every system can read them, and free tools
show them plainly.

Two things about that number:

- **A SMART warning is a very good reason to act.** Reallocated sectors that keep increasing means
  the disk is running out of spare places to put your data.
- **SMART passing is not a clean bill of health.** A meaningful share of disks fail with SMART
  reporting nothing wrong at all, because it only knows about the failures it counts.

So it is evidence in one direction only: a warning means trust it, silence means nothing.

## What to do, in the right order

**Copy your files off first. Before testing, before diagnosing, before anything.**

This is the one place in this course where the order is not a preference. A disk that is beginning
to fail has a number of reads left in it and nobody knows what that number is. Every test you run
spends some of them. A disk that survives one full copy might not survive an afternoon of being
investigated.

So: copy, to something that is not that disk. Then diagnose, at leisure, on a machine whose
failure now costs only money.

And afterwards, the honest conclusion: **a disk that has started failing is replaced, not
repaired.** Bad sectors can be marked and worked around, and it buys time rather than health.
