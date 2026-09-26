---
title: Three ways to get a file across
version: 1
---

A guest and its host are two computers, lesson 3, and a file gets from one to the other in the same
ways it would between any two computers, plus two the hypervisor adds:

| way | needs | good for |
|---|---|---|
| over the network: `scp`, a Windows share, a web download | a network between them, lesson 11 | anything, and it works the same on any hypervisor |
| a **shared folder** | the hypervisor's support and, usually, the guest's agent | files both sides keep working on |
| a **shared clipboard**, and drag and drop | the guest's agent, and a graphical desktop | a line of text, a path, one small file |

The network is the one that always works and never surprises anyone, and for a single file it is often
the quickest: this whole course has been doing it with `ssh`. The other two are conveniences, and like
most conveniences they trade a little safety for it. This lesson builds a shared folder in the lab, and
shows the clipboard's settings in VirtualBox.
