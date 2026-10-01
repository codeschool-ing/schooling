---
title: A switch with an empty table
version: 1
---

`sw1` has a bridge, `br0`, with the three ports, and nothing else:

```
ana@sw1:~$ ovs-vsctl show
9ee14f25-2944-48ee-ae8e-d8cfbeac168e
    Bridge br0
        fail_mode: secure
        datapath_type: netdev
        Port p3
            Interface p3
        Port br0
            Interface br0
                type: internal
        Port p2
            Interface p2
        Port p1
            Interface p1
```

`fail_mode: secure` means the switch does not fall back to behaving like an ordinary learning switch
when it has no controller. **It forwards exactly what its flow table says**, and the table is empty:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
ana@h1:~$ ping -c 2 -W 1 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1027ms
```

Not one packet crossed. A flow is a **match**, which fields of a packet it applies to, a
**priority**, which flow wins when several match, and **actions**, what to do with the packet.
`ovs-ofctl` writes them directly into the switch, two of them here, one for each direction between
ports 1 and 2:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 add-flow br0 "priority=10,in_port=1,actions=output:2" && ovs-ofctl -O OpenFlow13 add-flow br0 "priority=10,in_port=2,actions=output:1"
ana@h1:~$ ping -c 2 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.
From 203.0.113.129 icmp_seq=1 Destination Host Unreachable
64 bytes from 203.0.113.130: icmp_seq=2 ttl=64 time=1.33 ms

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 1 received, +1 errors, 50% packet loss, time 999ms
rtt min/avg/max/mdev = 1.333/1.333/1.333/0.000 ms
ana@h1:~$ ping -c 2 -W 1 203.0.113.131
PING 203.0.113.131 (203.0.113.131) 56(84) bytes of data.

--- 203.0.113.131 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1023ms
```

The first echo request failed at ARP, h1 got no answer to its question in time, and the second went
through. h3, on port 3, has no flow at all and is unreachable. The table now has counters:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
 cookie=0x0, duration=3.098s, table=0, n_packets=5, n_bytes=266, priority=10,in_port=1 actions=output:2
 cookie=0x0, duration=3.090s, table=0, n_packets=2, n_bytes=140, priority=10,in_port=2 actions=output:1
ana@sw1:~$ ovs-ofctl -O OpenFlow13 del-flows br0
```

**Every flow counts the packets and bytes it matched**, which is the switch telling you, flow by
flow, what it did. Then the flows are deleted again, for the controller to write.

This is configuration as forwarding: no routing protocol, no MAC learning, nothing inside the
switch deciding anything. Writing every flow by hand would be lesson 1's typing at a larger scale.
The controller is the program that writes them.
