---
title: When the controller stops
version: 1
---

The controller was stopped at the end of the last section. Two seconds later, the switch knows:

```
ana@sw1:~$ ovs-vsctl list controller | grep -E "^(target|is_connected)"
is_connected        : false
target              : "tcp:192.0.2.10:6653"
ana@h1:~$ ping -c 2 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.
64 bytes from 203.0.113.130: icmp_seq=1 ttl=64 time=0.321 ms
64 bytes from 203.0.113.130: icmp_seq=2 ttl=64 time=0.188 ms

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1029ms
rtt min/avg/max/mdev = 0.188/0.254/0.321/0.066 ms
```

**Traffic that already has flows keeps flowing.** The switch still holds what the controller wrote,
and in `secure` mode it keeps using it. That is how a controller can be restarted for an upgrade
without an outage.

Thirty-five seconds later, with no traffic in between:

```
ana@h1:~$ ping -c 2 -W 1 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1026ms

ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
 cookie=0x0, duration=53.805s, table=0, n_packets=2, n_bytes=196, priority=100,ip,nw_src=203.0.113.131,nw_dst=203.0.113.129 actions=drop
 cookie=0x0, duration=53.805s, table=0, n_packets=10, n_bytes=644, priority=0 actions=CONTROLLER:65535
```

**The learnt flows expired, and nothing replaced them.** The idle timeout removed the flows for h1
and h2, the table-miss sent the next packet to a controller that is not there, and the packet went
nowhere. The drop rule is still in the table, since it has no timeout; the network is now enforcing
its policy and forwarding nothing else.

That is the trade SDN makes, in one capture. A network of routers running OSPF keeps working when
any one of them fails, because every one of them decides. A network run by a controller **depends on
the controller**, so production controllers run as clusters of three or more, with the switches
connected to several at once; and the choice between `secure`, which keeps the controller's rules and
does nothing else, and `standalone`, which falls back to behaving like an ordinary switch, is a
decision about which failure is worse.
