---
title: The first day, which is when a machine gets its habits
version: 1
---

The build is finished when the operating system is installed and the machine is doing the job it
was bought for. That is another two hours, and most of it is waiting.

## Making the installer

You need a `USB` stick of `8 GB` or more and a tool that writes the installer onto it. Windows
has the *Media Creation Tool*; for anything else, `Rufus` or `balenaEtcher` or the `dd` command.
**Copying the files onto the stick does not work** — the stick has to be made bootable, which is
what those tools do.

The stick is erased in the process. That sentence is here because it is the one step of this
lesson that destroys something.

## Partitioning, in one paragraph

The installer will offer to use the whole drive, and on a new build with one drive, **let it.**
Modern installers create the three or four partitions an operating system needs — a boot
partition, the system, and a recovery area — and doing it by hand is a way to get it wrong.

The one decision worth making: **if there are two drives, install the system on the fast one** and
keep the large one for files. A `500 GB` NVMe for the system and a `2 TB` disk for everything else
is the arrangement that ages best.

## Drivers, and what has changed

The old ritual was a disc of drivers and an afternoon. Today a current Windows or Linux
installation arrives with almost everything working, and there are exactly two to fetch by hand:

- **the graphics driver**, from the card maker rather than from the update service, because it is
  the one that is genuinely newer and genuinely matters;
- **the chipset driver**, from the motherboard's own page, which mostly affects power management
  and is worth ten minutes.

Everything else — network, sound, storage — works out of the box, and a machine that came with a
driver disc is a machine whose drivers are three years old.

## The first day checklist

| | why now |
|---|---|
| **run every update** | there will be several rounds, and it wants restarts |
| **turn on disk encryption** | it is free at this point and a project later |
| **create a second, non-administrator account** for daily use | most damage needs administrator rights |
| **set up the backup before there is anything to lose** | see below |
| **write down the machine's specification** | you will need it and will not remember |
| **note the date** | warranties start now, and a build has no receipt for its whole |

## The one that is not optional

**Set up the backup today.** Not when there is something on the machine worth keeping — today,
while the machine is empty and the job takes ten minutes.

The reason is not diligence. It is that **a backup arranged later is a backup arranged after the
first thing you would have wanted back**, and every person who has lost something set theirs up
the week afterwards. An external drive and the operating system's own tool is enough; anything
automatic beats anything better that is done by hand.

That is the whole build. The machine in front of you is the four parts from lesson one, the three
from lesson two, the peripherals from lesson three, plugged into the ports from lesson four, and
half of it is talking over the radios from lesson five.
