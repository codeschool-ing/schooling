---
title: Workstation, Player and Fusion
version: 1
---

VMware makes three desktop hypervisors, all of them type 2:

- **Workstation Pro**, for Windows and Linux. Snapshots, clones, several networks, encrypted guests.
- **Workstation Player**, the free cut-down version for Windows and Linux, which ran one guest at a time
  and left out snapshots and clones.
- **Fusion**, the same thing for a Mac.

**The terms moved in 2024**, after Broadcom bought VMware. Player was discontinued, and Workstation Pro
and Fusion Pro became free, first for personal use and then, from November 2024, for business use as
well. Downloads now come from Broadcom's support site, behind a free account. Any of that may have
moved again by the time you read it, so **check the vendor's current terms before installing it on a
company's computer**, where a licence is a legal question rather than a technical one.

What a support technician meets in practice is a mix: new Workstation installs, and old copies of
Player that still start their guests perfectly well and will never get another update. None of what
follows depends on which one it is.

VMware Workstation is not installed on this course's host, and nothing in this lesson ran it. What did
run is the part of VMware every hypervisor shares: its disk format and its way of packing up a machine.
