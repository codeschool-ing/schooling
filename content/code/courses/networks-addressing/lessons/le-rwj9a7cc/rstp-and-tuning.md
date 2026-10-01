---
title: Rapid spanning tree, and choosing the tree on purpose
version: 1
---

Thirty seconds of silence after a cable fails is the original protocol working as designed. **The
timers are slow because classic STP has no way to know the network has settled, so it waits.** The
fix, published in 2001, does not shorten the wait. It replaces most of it with a conversation.

## RSTP: asking instead of waiting

**Rapid Spanning Tree** (RSTP, IEEE 802.1w, folded into 802.1D in 2004) keeps the same election,
the same bridge IDs and the same costs. Three things change.

- **An alternate port is a backup root port, chosen in advance.** Classic STP blocks the spare
  port and computes nothing more for it. RSTP marks it as the alternate route to the root, so when
  the root port fails the alternate becomes the root port at once, with no listening and no
  learning. In the lab's triangle, `sw2`'s blocked `p3` is exactly that port.
- **On a point-to-point cable, two switches agree instead of timing out.** A switch that wants to
  forward on a port sends a *proposal*. The switch at the other end makes sure its own ports cannot
  form a loop, then answers with an *agreement*, and the port forwards straight away. The handshake
  runs from switch to switch outwards from the change, and on a network of point-to-point links
  that takes around a second, often less.
- **Edge ports skip the whole process.** A port marked as an edge port faces a computer, not
  another switch, so it goes to forwarding as soon as the cable is plugged in.

The states shrink to three: **discarding** (blocking and listening merged, since neither forwards
anything), **learning** and **forwarding**. The roles grow: root, designated, alternate, and
*backup*, a second port on a cable where the switch already has the designated port.

RSTP speaks to an old 802.1D switch in the old protocol, port by port, so the two can be mixed. The
cost of mixing is that the fast handshake works only where both ends speak RSTP.

**The lab could not show any of this.** The Linux bridge in the kernel implements the original
802.1D, which is why every capture in this lesson has listening and learning in it. RSTP on Linux
comes from a separate daemon, `mstpd`, which was not run here, so this section carries no output.

## One tree per group of VLANs

A single tree blocks the same cable for every VLAN (lesson 19), so half the cables in a redundant
design carry nothing. **MSTP** (*Multiple Spanning Tree*, IEEE 802.1s, now part of 802.1Q) groups
VLANs into instances and runs a tree per instance, each with its own root. With two instances and
two roots, VLAN 10 can block one cable and VLAN 20 the other, and both cables carry traffic.
Vendors had their own per-VLAN versions first, Cisco's PVST+ and Rapid PVST+ among them, and they
are still common on that equipment.

## Choosing the tree instead of inheriting it

A network that runs on defaults lets MAC addresses pick its root, as the root-election section
showed. Three decisions avoid that.

**Set the root.** Give the core switch, the one in the middle of the traffic, the lowest priority,
4096 or even 0, and a second core switch the next value, 8192, so that when the first fails the
backup root is also a choice. The priority change in the failover section did exactly this on a
small scale.

**Mark the ports that face computers as edge ports.** Under classic STP, a PC that starts up waits
about 30 seconds before its first frame passes, which is long enough for a DHCP client (lesson 10)
to give up. On Cisco equipment the setting is called *PortFast*. An edge port that receives a BPDU
stops being an edge port, which is safe; the next section is about doing more than that.

**Leave the timers alone.** Shortening hello, max age or forward delay by hand to speed up classic
STP risks a port forwarding before the tree has settled, which is the loop this lesson started
with. Running RSTP is the way to get the speed.
