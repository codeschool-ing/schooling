---
title: The ranges that mean something on their own
version: 1
---

Some addresses tell you something before you send a single packet. A PC showing `169.254.10.10`
has a problem, a server listening on `0.0.0.0` accepts connections on every address it has, and an
address starting with 224 is a group rather than a machine. **Recognising these ranges is half of
reading an address**, and this section collects them.

The one that shows up most in support work:

```
ana@pc1:~$ ipcalc -b 169.254.10.10
Address:   169.254.10.10        
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   169.254.10.0/24      
HostMin:   169.254.10.1         
HostMax:   169.254.10.254       
Broadcast: 169.254.10.255       
Hosts/Net: 254                   Class B, APIPA

```

`169.254.0.0/16` is **link-local**. A machine that asked for an address by DHCP and heard nothing
back picks one from this range for itself, checks nobody on the link has it, and uses it. Windows
calls the mechanism APIPA (Automatic Private IP Addressing), and that is the label this ipcalc
prints. The `Class B` beside it is the first-octet rule from this lesson's second section and means
nothing here. **A PC with a 169.254 address has not reached its DHCP server**: it can talk to other
machines on the same cable that did the same, and to nothing beyond, because routers do not forward
link-local addresses. Lesson 10 is about why the DHCP server did not answer.

Next, an address that belongs to no local network at all:

```
ana@pc1:~$ ip route get 8.8.8.8
8.8.8.8 via 10.20.10.1 dev eth0 src 10.20.10.21 uid 1000 
    cache 
```

`ip route get` asks the routing table what it would do with a packet, and sends nothing. `8.8.8.8`
is a public address on the real internet, which this lab cannot reach; the answer is the same
anyway: **an address on no network pc1 is attached to goes to the gateway**, `via 10.20.10.1`, out
of `eth0`, from `10.20.10.21`. Lesson 14 reads routing tables in full.

`0.0.0.0` means "no particular address", and which sense applies depends on where it appears. A
machine with no address yet uses it as its source when it asks DHCP for one. As a route, `0.0.0.0/0`
is the default route, the one that matches everything. And in a list of sockets it means "any":

```
ana@pc1:~$ ss -tln
State Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
root@srv:~# ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5        10.20.10.10:80        0.0.0.0:*          
```

pc1 listens on nothing, so its list is only the header. srv runs the office's web server, and
`10.20.10.10:80` says it listens on port 80 of that one address only. The peer column,
`0.0.0.0:*`, means **any address on any port may connect**. A service bound to `0.0.0.0:80` instead
would accept connections on every address the machine has, loopback included, which is the
opposite of the `127.0.0.1` binding from the loopback section.

Everything in one table:

| range | what it is | where in this course |
|---|---|---|
| `0.0.0.0/8` | "this network"; `0.0.0.0` as "no address" or "any" | this section; lesson 14 for `0.0.0.0/0` |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | private (RFC 1918) | this lesson; NAT in lesson 11 |
| `100.64.0.0/10` | shared, for carrier-grade NAT (RFC 6598) | lesson 11 |
| `127.0.0.0/8` | loopback | this lesson |
| `169.254.0.0/16` | link-local, a machine's own pick when DHCP fails | lesson 10 |
| `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24` | documentation (RFC 5737) | the whole lab |
| `224.0.0.0/4` | multicast, the old class D | lesson 16 |
| `240.0.0.0/4` | reserved, the old class E | — |
| `255.255.255.255` | limited broadcast | lesson 10 |

Everything else is ordinary public space, given out by the regional registries to providers and
organisations. **None of the ranges in the table names a machine you can reach across the public internet**,
which is the practical test. If a packet with a source from one of them arrives at your network from
outside, something upstream is misconfigured or somebody forged it, and a firewall rule that drops
such packets at the edge costs nothing.
