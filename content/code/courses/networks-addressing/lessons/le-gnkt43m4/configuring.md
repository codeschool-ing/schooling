---
title: Typing a route, and watching it fail
version: 2
---

The lab is three routers in a line, a PC at each end, and a spare cable from r1 straight to r3 that
this section ignores. **Each router starts with its connected routes and nothing else**, and every other
route in the lesson is typed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"The lab for this lesson, three routers in a line. pc1, 10.20.1.10, sits on 10.20.1.0/24 behind r1. r1 joins r2 over 10.20.12.0/30 (r1 is 10.20.12.1, r2 is 10.20.12.2), and r2 joins r3 over 10.20.23.0/30 (r2 is 10.20.23.1, r3 is 10.20.23.2). pc3, 10.20.3.10, sits on 10.20.3.0/24 behind r3. A spare cable, 10.20.13.0/30, runs from r1 (10.20.13.1) straight to r3 (10.20.13.2).\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"150\" y=\"30\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"160\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.1.1</text><text x=\"160\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.1</text><text x=\"160\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.1</text><rect x=\"300\" y=\"30\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"310\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.2</text><text x=\"310\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.1</text><rect x=\"450\" y=\"30\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"460\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.2</text><text x=\"460\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.2</text><text x=\"460\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.3.1</text><rect x=\"610\" y=\"30\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"620\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.10</text><path d=\"M110 67 L150 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M268 67 L300 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M418 67 L450 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568 67 L610 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"130\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"284\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.0/30</text><text x=\"434\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.23.0/30</text><text x=\"589\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M209 104 L209 170 L509 170 L509 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"359\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.13.0/30</text><text x=\"359\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the spare cable</text></svg>", "caption": "The lab for this lesson. Each router starts with its connected networks only; every other route is typed."}
```

Save it as `~/netlab/chain.sh` and build it with `sudo bash ~/netlab/netlab.sh up chain`:

```bash
# ~/netlab/chain.sh: three routers in a line with a spare cable from r1 to r3,
# a PC at each end, and no routes but the connected ones.
#
#   pc1 --- r1 --(10.20.12.0/30)-- r2 --(10.20.23.0/30)-- r3 --- pc3
#   10.20.1.0/24 \_________(10.20.13.0/30, the spare)_____/  10.20.3.0/24
local n
node pc1; node pc3
for n in r1 r2 r3; do node $n router; done
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc3 eth0 r3 eth0; addr pc3 eth0 10.20.3.10/24; addr r3 eth0 10.20.3.1/24; gw pc3 10.20.3.1
link r1 eth1 r2 eth1; addr r1 eth1 10.20.12.1/30; addr r2 eth1 10.20.12.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.23.1/30; addr r3 eth2 10.20.23.2/30
link r1 eth3 r3 eth3; addr r1 eth3 10.20.13.1/30; addr r3 eth3 10.20.13.2/30
```

The file gives every interface its address and the two PCs their gateways, and nothing more: the
routers know only the networks on their own cables until this lesson types the rest.

r1 knows the three networks its cables touch. pc1 asks it for pc3, and r1 has no line that matches
`10.20.3.10`, so it says so:

```
root@r1:~# ip route
10.20.1.0/24 dev eth0 proto kernel scope link src 10.20.1.1 
10.20.12.0/30 dev eth1 proto kernel scope link src 10.20.12.1 
10.20.13.0/30 dev eth3 proto kernel scope link src 10.20.13.1 
ana@pc1:~$ ping -c 1 -W 1 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.
From 10.20.1.1 icmp_seq=1 Destination Net Unreachable

--- 10.20.3.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

`Destination Net Unreachable` from `10.20.1.1` is r1 refusing, the same message lesson 14 met. The fix
looks obvious: tell r1 where `10.20.3.0/24` is, and tell r2 too, since r1 will hand the packet to r2.

On Linux the command is `ip route add NETWORK via NEXT-HOP`. **The next hop has to be an address on a
network this router is connected to**, because the router will look up its MAC address with ARP and put
the frame on that cable. r1 reaches r2 at `10.20.12.2`, the far end of their shared `/30`; r2 reaches r3
at `10.20.23.2`:

```
root@r1:~# ip route add 10.20.3.0/24 via 10.20.12.2
root@r2:~# ip route add 10.20.3.0/24 via 10.20.23.2
ana@pc1:~$ ping -c 1 -W 2 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.

--- 10.20.3.10 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 1ms

```

No error this time, and no reply either: one packet sent, none received, and **nothing at all to say
why**. From pc1, this is indistinguishable from pc3 being switched off.

Meanwhile a `tcpdump` was running on pc3, and it printed its capture when it ended:

```
root@pc3:~# timeout 6 tcpdump -n -i eth0 -c 3 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:35:23.124898 IP 10.20.1.10 > 10.20.3.10: ICMP echo request, id 37, seq 1, length 64
08:35:23.126700 IP 10.20.3.10 > 10.20.1.10: ICMP echo reply, id 37, seq 1, length 64
08:35:23.127054 IP 10.20.3.1 > 10.20.3.10: ICMP net 10.20.1.10 unreachable, length 92
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Read the three lines in order. The request **arrived**, so the two routes worked. pc3 **answered**, so
pc3 is fine. Then `10.20.3.1`, which is r3, sent pc3 `ICMP net 10.20.1.10 unreachable`: r3 had a reply
for `10.20.1.10` and no route to `10.20.1.0/24`. **The error went to the sender of the packet r3 could
not deliver, and that sender was pc3**, so pc1 never heard about it.

That is the most common mistake with static routes, and the capture shows why it is so confusing: the
side that notices the failure is the side nobody is looking at. When a ping between two networks fails
silently, look at the far end before blaming the forward path.

## The same route on other equipment

The idea is the same everywhere, and only the spelling changes. None of these were run in this lab:

| where | the route r1 needs |
|---|---|
| Linux, as above | `ip route add 10.20.3.0/24 via 10.20.12.2` |
| FRR's vtysh, `configure terminal` | `ip route 10.20.3.0/24 10.20.12.2` |
| Cisco IOS, `configure terminal` | `ip route 10.20.3.0 255.255.255.0 10.20.12.2` |

**A route added with `ip route add` lasts until the machine restarts.** A real Linux router keeps its
routes in its network configuration, and a router running FRR or IOS keeps them in its saved
configuration, which is why the second and third lines are the ones you find on equipment.
