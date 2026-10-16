---
title: How two primaries happen
version: 1
---

**Split-brain** is two servers accepting writes for the same database at the same time, each
believing it is the primary. Lesson 15 made one with a reboot. Lesson 16's cluster manager exists to
prevent exactly that, and it does, with one assumption underneath: that a primary which **cannot
renew** its leader key will notice and stop.

Noticing takes a process that is running. Three ordinary events stop the process and leave the
database running:

- **A pause.** The hypervisor suspends a virtual machine for a snapshot or a migration, the process
  waits on a disk that has stopped answering, or the machine is too overloaded to schedule it. The
  pause ends minutes later and the process carries on from where it was, unaware that time passed.
- **A partition.** The primary's machine loses its connection to etcd and keeps its connection to
  some of the application servers.
- **A crash of the manager alone.** The Patroni process dies and PostgreSQL, a separate process,
  goes on serving.

In each case the leader key expires, a replica takes it, promotes itself, and the old primary is
still taking writes from whoever can reach it. The cluster manager did everything right. What is
missing is a way to make sure the old primary has **actually stopped** before the new one starts,
and that is called **fencing**.

The next section produces the first case on purpose.
