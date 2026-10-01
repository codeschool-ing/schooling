---
title: A BGP session, and the router that refuses to talk
version: 1
---

**BGP neighbours are configured, not discovered.** OSPF found its neighbours with hellos on every interface;
BGP talks only to the addresses you name, each with the AS you expect on the other end, over a **TCP
connection to port 179**. Being TCP, it gets reliable, ordered delivery for free, and it sends a full
table once and then only the changes.

edge's configuration names its AS, a router ID, the two providers, and the one network it will announce:

```
root@edge:~# vtysh -c "configure terminal" -c "router bgp 64500" -c "bgp router-id 192.0.2.1" -c "neighbor 192.0.2.2 remote-as 64501" -c "neighbor 192.0.2.6 remote-as 64502" -c "address-family ipv4 unicast" -c "network 203.0.113.0/24"
```

`neighbor 192.0.2.2 remote-as 64501` says *the router at that address is in AS 64501*. A neighbour in a
different AS is an **eBGP** session (*external*); in the same AS it would be **iBGP**, which large networks
use to carry BGP routes between their own border routers and which this lesson does not need.
`network 203.0.113.0/24` is the company's block, the prefix edge will originate.

A few seconds later:

```
root@edge:~# vtysh -c "show bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 192.0.2.1, local AS number 64500 vrf-id 0
BGP table version 1
RIB entries 1, using 192 bytes of memory
Peers 2, using 1448 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
192.0.2.2       4      64501         5         3        0    0    0 00:00:05     (Policy) (Policy) N/A
192.0.2.6       4      64502         5         3        0    0    0 00:00:05     (Policy) (Policy) N/A

Total number of neighbors 2
```

Read the two lines. `V 4` is BGP version 4. `MsgRcvd 5` and `MsgSent 3` show messages flowing, and
`Up/Down 00:00:05` is how long the session has been up. The state column holds a word while a session is
not established (`Idle`, `Connect`, `Active`) and the number of prefixes received once it is.

**Here it holds `(Policy)`, in both directions.** The session is established and nothing is being
exchanged, because FRR follows RFC 8212: **an eBGP session with no policy configured accepts nothing and
announces nothing**. It is a deliberate refusal, written into a standard after enough networks announced
things they never meant to because a router's default was *send everything*. The next section writes
that policy.

## What to check when a session will not come up

The state column is the first thing to read:

- **`Active` or `Connect`** for a long time: the TCP connection is not completing. Check that the
  neighbour's address is reachable, that the other side has a matching `neighbor` line pointing back, and
  that nothing filters TCP port 179.
- **A session that comes up and drops**: the two sides disagree about something in the opening exchange,
  most often the AS number. A `remote-as` that does not match what the neighbour says it is closes the
  session.
- **`(Policy)`**: it works, and is waiting for you to say what may cross it.

None of those failures were staged in this lab; the session here came up at the first attempt.
