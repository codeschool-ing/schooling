---
title: Storage, and the one change that makes an old machine feel new
version: 1
---

Storage is what survives the power going off: your files, your programs as installed, the
operating system itself. Two technologies do the job, they are not two grades of the same thing,
and the difference between them is the largest single change you can make to how a computer
feels.

## A hard disk is a record player

An **HDD** is metal platters spinning at 5 400 or 7 200 revolutions a minute, with an arm that
swings across them to reach a track. To read something, the arm moves and then the platter has
to bring the right spot round underneath it.

That wait has a name — **seek time** — and it is about 10 milliseconds. It is not an electronic
delay. It is the time a physical object takes to move, and no amount of engineering has made
mechanics keep up with electronics.

## An SSD has nothing that moves

An **SSD** is memory chips. No arm, no platter, nothing to wait for. Reaching any address takes
about 0.1 milliseconds whatever was read before it.

That is roughly **a hundred times faster to reach a thing**, and the gap gets wider still for
the work computers actually do, which is reaching thousands of small things scattered all over.

| | hard disk | SSD |
|---|---|---|
| reaching one thing | ~10 ms | ~0.1 ms |
| reading in a straight line | ~150 MB/s | 500 MB/s, or 3 000+ on NVMe |
| moving parts | yes | none |
| cost per gigabyte | lowest there is | several times more |
| what it is good for | archives, backups, bulk | anything you wait for |

## The upgrade that actually works

An eight-year-old laptop with a hard disk in it, given an SSD, boots in fifteen seconds instead
of ninety and opens programs instantly. The processor is the same processor. Nothing about it
got faster.

That is worth sitting with, because it is the lesson's whole argument in one purchase: **the
machine was never slow. It was waiting**, and the waiting was all in one place.

## SATA and NVMe, briefly

You will see both words on SSDs and the difference is how the drive is *connected*, not what it
is made of:

- **SATA** is the older connection, shared with hard disks, and tops out around 550 MB/s.
- **NVMe** plugs straight into the motherboard's fast lanes and reaches 3 000 to 7 000 MB/s.

In honesty: going from a hard disk to any SSD is transformative, and going from a SATA SSD to an
NVMe one is a number you can measure and rarely feel. The first step is the one that matters.

## And a word about capacity, which is not speed

`512 GB` says how much fits, and nothing about how fast it is. A full drive does get slower —
below about 10% free, an SSD has fewer spare blocks to write into and has to shuffle — so
**leave some empty**. That is the only place where the two numbers touch each other at all.
