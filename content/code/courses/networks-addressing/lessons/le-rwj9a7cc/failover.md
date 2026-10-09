---
title: Moving the root, and losing a cable
version: 2
---

The tree is not fixed. It is recomputed whenever something changes, and two changes matter in
practice: **an administrator choosing a different root, and a cable failing**. The first is
deliberate and the second is what spanning tree is for. Both were done in the lab.

## Choosing the root with a priority

The priority is the part of the bridge ID a person sets. Lowering it on one switch makes that
switch win the election whatever its MAC address. Here it went from the default 32768 to 4096 on
`sw3`:

```
root@sw3:~# ip link set br0 type bridge priority 4096
root@sw3:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port
bridge_id:1000.02a59d312a8c
root_id:1000.02a59d312a8c
root_port:0
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw2:~# bridge link show
461: p1@if462: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 2 
464: p3@if463: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
469: p10@if470: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
```

`1000` is 4096 in hexadecimal, and `sw3`'s bridge ID is now also the root ID: **`sw3` is the root**.
The blocked port moved too. Now the cable furthest from the root is `sw1`–`sw2`. Both its ends are
one cable from `sw3`, the cost ties again, and `sw1`'s lower bridge ID makes `sw1`'s `p2` the
designated port, so **`sw2` blocks `p1`** this time and forwards on `p3`, the port that was blocked
before.

On many switches the priority can only be set in steps of 4096, and the reason is in the same two
bytes: the lower 12 bits carry a VLAN number, so that a switch can run one tree per VLAN. The
rapid-spanning-tree section of this lesson comes back to that.

## A cable fails

For the second test the root went back to `sw1` (priority 32768 on `sw3` again, then a wait for the
tree to settle), which put `sw2`'s `p3` back in `blocking`. On `pc2`, a ping to `pc1` was started,
one packet a second for 60 seconds. Two seconds later the cable between `sw1` and `sw2` was pulled,
`ip link set p2 down` at a root prompt on sw1,
and `sw2`'s `p3` was read every six seconds:

```
root@sw2:~# bridge link show
461: p1@if462: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
464: p3@if463: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 2 
469: p10@if470: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw2:~# for i in 1 2 3 4 5 6 7; do date +%T; bridge link show dev p3 | grep -o "state [a-z]*"; sleep 6; done
09:10:11
state listening
09:10:18
state listening
09:10:24
state listening
09:10:30
state learning
09:10:36
state learning
09:10:43
state forwarding
09:10:49
state forwarding
```

The blocked port is the one that takes over. It went to `listening`, then `learning` somewhere
between 09:10:24 and 09:10:30, then `forwarding` somewhere between 09:10:36 and 09:10:43. The samples
are six seconds apart, so that is as precisely as this capture can place each change. Meanwhile, on
`pc2`, the ping had been running the whole time, and printed its summary when it finished:

```
ana@pc2:~$ ping -c 60 -i 1 -q 10.20.10.21
PING 10.20.10.21 (10.20.10.21) 56(84) bytes of data.

--- 10.20.10.21 ping statistics ---
60 packets transmitted, 30 received, 50% packet loss, time 60088ms
rtt min/avg/max/mdev = 0.441/1.246/11.610/2.076 ms
```

**60 sent, 30 answered: half a minute with no path between two PCs, on a network with a perfectly
good spare cable.** That is two forward delays, 15 seconds of listening and 15 of learning, during
which the port forwarded nothing.

## The three timers

| timer | default | what it decides |
| --- | --- | --- |
| hello time | 2 s | how often the root's BPDUs are sent |
| max age | 20 s | how long a switch keeps the last BPDU it heard before deciding the path behind it is gone |
| forward delay | 15 s | how long a port spends in listening, and again in learning |

`sw2` did not wait for max age, because the dead cable was on its own root port and it saw the
signal go. **When the failure is somewhere else, a switch learns of it only because BPDUs stop
arriving**, and it first waits out max age: 20 seconds, then 30 more of listening and learning,
about 50 seconds in all. For a phone call or a database connection, both numbers are an outage,
and they are why the next section exists.
