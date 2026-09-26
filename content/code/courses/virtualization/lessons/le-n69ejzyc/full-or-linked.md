---
title: Full or linked?
version: 1
---

Every hypervisor offers both kinds of clone, under these names or close ones:

| | full clone | linked clone |
|---|---|---|
| disk | a complete copy, 804M here | a thin layer, 196K here when new |
| made in | as long as copying the disk takes | a moment |
| depends on | nothing | the template, which must never change |
| moving it elsewhere | copy one file | copy the whole chain, or make it full first |
| right for | a machine that will live on its own | a lab, and many short-lived copies |

VirtualBox's *Clone* dialog asks *Full clone* or *Linked clone*, and a linked one needs a snapshot of the
original to hang from. VMware Workstation asks the same, from a snapshot or the current state. Proxmox
makes linked clones from a template when the storage supports them.

Whichever kind, the rule of the first half of this lesson holds: **clone a sealed template, not a
machine somebody has used.** A clone of a used machine is a second copy of that machine, name and keys
included, and the problems start the moment both are on the same network.
