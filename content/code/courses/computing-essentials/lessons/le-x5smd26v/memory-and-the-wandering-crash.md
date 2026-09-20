---
title: Memory, and the crash that will not stay still
version: 1
---

A faulty memory module is the hardware fault that looks least like one. Nothing is slow, nothing
makes a noise, nothing is warm. Things simply go wrong, in different places, for no reason that
anybody can connect.

## The signature is the randomness itself

A software bug is reproducible: the same file, the same button, the same step. **A memory fault
moves.** Yesterday it was the browser, today it is the photo editor, tomorrow it is the machine
restarting while nobody is at it.

So the tell is not any one crash. It is the pattern:

- crashes in **different programs**, with different messages;
- a machine that **restarts by itself**, with no pattern anybody can name;
- a file that was fine yesterday and is corrupt today, **with no disk symptoms at all**;
- a system that fails to install or update, repeatedly, at a different point each time.

That last one is worth knowing on its own: **an installation that fails at a different place each
time is memory until proved otherwise.** Installing reads and writes an enormous amount, so it
hits a bad location that ordinary use might miss for weeks.

## Testing it is free, and it is not a guess

Every system can boot a **memory test** — a program that runs before the system does, writes
patterns across every location and reads them back. It is one of the few tests in this course
that gives an unambiguous answer.

Two practical notes. It takes hours, and it wants them: a single pass finds the worst faults, and
the borderline ones show up on the third or fourth. And it runs from a stick, so it does not care
whether the installed system still starts.

## And if it fails

Memory almost always comes in two or more modules, which makes the next step a swap in exactly
the sense of the previous lesson: **take one out and run on the other.** The fault follows the
faulty module, and two tests settle which.

This is one of the easiest repairs there is on a desktop, and on many laptops: a clip at each end,
and the module lifts out at an angle. It is also one of the cheapest parts to replace.

## The one that is not a fault at all

**Running out of memory** is a different thing and it is not a defect. A machine with too little
memory for what is being asked of it becomes very slow, because the system starts using the disk
as an overflow — and the disk is thousands of times slower.

The signature is the opposite of the fault above: **entirely predictable.** It happens when many
things are open, it gets better when they are closed, and it never corrupts anything. That is a
machine to add memory to, not a machine to repair.
