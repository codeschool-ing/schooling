---
title: Switches, mirror ports and why the lab floods
version: 1
---

The sensor saw traffic between `remote` and `www`, two other machines. On a modern network that is
not supposed to happen by itself: a **switch** learns which MAC address sits behind which port and
sends each frame only to the port it is addressed to. A machine plugged into a switch normally hears
its own traffic, broadcasts, and nothing else.

A defender who wants a sensor to see a segment asks the switch for a copy. A **mirror port**, called
SPAN on Cisco equipment, receives a copy of every frame crossing chosen ports or VLANs. The other
option is a **network tap**, a small device inline on a cable that copies both directions to a
monitoring port and cannot be reconfigured from the network.

The lab has neither, so it cheats in a way worth saying out loud: the bridge that plays the DMZ's
switch is told to forget where every address is, and floods every frame to every port, like the hubs
switches replaced. That is why the sensor can hear. **On a real network, a machine hearing traffic
that is not addressed to it means one of three things**:

| cause | who arranged it |
|---|---|
| a mirror port or a tap | the network's administrators, for a sensor |
| a switch whose address table has been overflowed, so it floods like a hub | an attacker, or a fault |
| a machine that has convinced others to send it their traffic, by lying in ARP | an attacker, next section |

The second one has a direct defence in the switch. **Port security** limits how many MAC addresses a
port may learn, and shuts the port or drops the excess when a machine behind it presents more. A desk
port has one computer, sometimes a phone as well; a port that suddenly presents hundreds of addresses
is not a desk.
