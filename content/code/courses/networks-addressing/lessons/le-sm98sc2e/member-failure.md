---
title: Losing one cable of the bundle
version: 2
---

In lesson 20 a pulled cable cost a ping half a minute, because spanning tree had to walk a blocked
port through listening and learning before it would forward. **In a LAG there is no blocked port
to wake up**: the other member is already forwarding, and the bond only has to stop using the one
that went dead.

## Pulling e1 while a ping runs

On `pc1`, a ping to `pc3` was started, two packets a second for ten seconds. Two seconds in, cable
`e1` was pulled, by setting `sw2`'s end of it down: `ip link set e1 down` at a root prompt on sw2. The ping printed its summary when it finished,
and then `sw1` was asked about its members:

```
ana@pc1:~$ ping -c 20 -i 0.5 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 9553ms
rtt min/avg/max/mdev = 0.538/1.079/4.054/0.725 ms
root@sw1:~# grep -A3 "Slave Interface" /proc/net/bonding/bond0
Slave Interface: e1
MII Status: down
Speed: 10000 Mbps
Duplex: full
--
Slave Interface: e2
MII Status: up
Speed: 10000 Mbps
Duplex: full
root@sw1:~# ip -br link show bond0
bond0            UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
```

**20 sent, 20 received.** `e1` reports `MII Status: down`, `e2` is `up`, and `bond0` itself is still
`UP` with `LOWER_UP`: to the switch, its uplink never went away. Compare lesson 20's 30 replies lost
out of 60.

Be precise about what this proves. The capture does not say which cable the pings to `pc3` had been
hashed onto. If they were on `e2` all along, the test would have passed without the bond doing
anything for them. **What it does show, whichever member they used, is a link that kept working with
one of its two cables gone**, and a bond that went on reporting itself up. The traffic that had been
on `e1` moved to `e2`, because a hash over the members still up has only one answer left.

## How the bond notices

There are two ways, and they catch different failures.

- **The link signal.** `miimon 100` has the bond check each member's carrier every 100
  milliseconds. A cable pulled or cut, or a port on the far switch shut down, is seen within one
  check. This is what happened here.
- **LACP itself.** A member stays in the LAG only while LACPDUs from the partner keep arriving.
  With `lacp_rate fast` they come every second, and **a member that misses three in a row is taken
  out, about three seconds, even if its link light stays on.** That is the failure the signal
  cannot see: a media converter in the middle of the cable, or a far-end switch that has crashed
  with its ports still lit. With the slow rate the same wait is 90 seconds. A static LAG has neither
  check beyond the signal.

## What is left after the failure

The LAG carries on at half its capacity, and nothing on the network has to recompute anything.
That is also its quiet risk. **A bond with one member down looks healthy from above**: `bond0` is
`UP`, the pings answer, and the only sign is a line in `/proc/net/bonding/bond0` or the switch's
equivalent. The `Min links: 0` in the previous section's output is the setting that would change
that: with `min_links 2`, the bond would declare itself down when fewer than two members were up,
so that a design which needs both cables fails loudly instead of running slow. Whichever you choose,
a monitoring system should be watching the member count, because nobody notices a missing half
until the day the remaining cable is full.
