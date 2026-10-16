---
title: Fencing: making sure the old primary has stopped
version: 1
---

Every split-brain above comes from one gap: the new primary started while the old one was still able
to accept writes. **Fencing** closes it by making the old primary unable to write **before** the new
one is promoted. The ways to do it differ in what they cost and in what they trust:

| fencing | how it stops the old primary | what it costs |
|---|---|---|
| **watchdog** | a timer in the kernel, which Patroni must reset on every loop; if Patroni stops resetting it, the kernel reboots the machine, before the leader key can expire | a reboot of a machine that may only have been slow |
| **STONITH** ("shoot the other node in the head") | the new primary, or the manager, powers the old machine off through its management interface or the cloud provider's API | credentials that can power off a database server, and a dependency on that interface answering |
| **network fencing** | the old primary's network port, or its address in a load balancer, is cut | a network you control, and the cut has to reach every path to it |
| **synchronous replication** | the old primary cannot confirm a commit without a standby, and its standby has moved to the new primary | the commit latency of lesson 12 |

## The watchdog

The watchdog is the one Patroni builds in, and it covers exactly the freeze in this lesson: Patroni
arms the timer to fire a few seconds before its key expires, so a frozen Patroni means a rebooted
machine, and a rebooted machine accepts nothing. On a virtual machine, the kernel's software watchdog
provides the device:

```sh
sudo modprobe softdog
sudo chown ana /dev/watchdog
```

and three lines in each node's file, beside `postgresql:`:

```yaml
watchdog:
  mode: required
  device: /dev/watchdog
```

`required` makes Patroni refuse to become the leader on a node where the watchdog cannot be armed, so
a missing device is found at start-up rather than during a failover. The machine these transcripts
come from has no watchdog device and cannot load one, so this course has no transcript of it; on your
virtual machine, freezing the leader's Patroni as above should end with the virtual machine
rebooting, and the order placed on it never confirmed.

`softdog` is a timer inside the same kernel it is meant to restart, so a kernel that hangs takes it
down too. Servers have a hardware watchdog for that, and cloud providers offer an equivalent; for
learning, the software one shows the mechanism.
