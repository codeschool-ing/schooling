---
title: The address that changes at the router
version: 1
---

Source NAT is a rewrite in one direction and its undoing in the other, and one ping is enough to see
both. On r1, `tcpdump -i any` listens on every interface at once and prints which one each packet
crossed. It was started first and kept running while pc1 pinged an address outside. pc1's terminal
printed:

```
ana@pc1:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=62 time=21.8 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 21.845/21.845/21.845/0.000 ms
```

and meanwhile, on r1, tcpdump had printed:

```
root@r1:~# timeout 6 tcpdump -n -i any -c 4 icmp
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
08:24:44.835307 eth0  In  IP 10.20.10.21 > 192.0.2.80: ICMP echo request, id 14, seq 1, length 64
08:24:44.845874 eth1  Out IP 203.0.113.2 > 192.0.2.80: ICMP echo request, id 14, seq 1, length 64
08:24:44.849379 eth1  In  IP 192.0.2.80 > 203.0.113.2: ICMP echo reply, id 14, seq 1, length 64
08:24:44.850008 eth0  Out IP 192.0.2.80 > 10.20.10.21: ICMP echo reply, id 14, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Four lines, one packet each, and the interface column tells the story:

1. `eth0  In`: the echo request arrives from the office, from `10.20.10.21` to `192.0.2.80`.
2. `eth1  Out`: the same request leaves towards the provider, **now from `203.0.113.2`**. Only the
   source changed: the destination, the ICMP `id 14` and `seq 1` are as they were.
3. `eth1  In`: the reply comes back to `203.0.113.2`, the only address the far end ever saw.
4. `eth0  Out`: r1 sends the reply into the office **to `10.20.10.21`**, putting back what it took out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"One ping through r1, in the four packets tcpdump printed. 1: the echo request arrives on eth0 from 10.20.10.21 to 192.0.2.80. 2: it leaves on eth1 from 203.0.113.2 to 192.0.2.80; the source was rewritten. 3: the reply arrives on eth1 from 192.0.2.80 to 203.0.113.2. 4: it leaves on eth0 from 192.0.2.80 to 10.20.10.21; the destination was rewritten back.\"><defs><marker id=\"snat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">office side, eth0</text><text x=\"550\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">provider side, eth1</text><rect x=\"330\" y=\"32\" width=\"60\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">r1</text><text x=\"55\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1  request in</text><rect x=\"55\" y=\"54\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"67\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">src 10.20.10.21</text><text x=\"67\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dst 192.0.2.80</text><path d=\"M285 79 L326 79\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"435\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2  request out</text><rect x=\"435\" y=\"54\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">src 203.0.113.2</text><text x=\"447\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dst 192.0.2.80</text><path d=\"M390 79 L431 79\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"435\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3  reply in</text><rect x=\"435\" y=\"154\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src 192.0.2.80</text><text x=\"447\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">dst 203.0.113.2</text><path d=\"M435 179 L394 179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"55\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4  reply out</text><rect x=\"55\" y=\"154\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"67\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src 192.0.2.80</text><text x=\"67\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">dst 10.20.10.21</text><path d=\"M330 179 L289 179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the field drawn in amber is the one r1 rewrote</text></svg>", "caption": "Source NAT on one ping. On the way out r1 replaces the source; on the way back it replaces the destination, using what it noted at step 2."}
```

How did r1 know, at step 4, that a reply for 203.0.113.2 belonged to pc1? It remembered. At step 2 it
wrote an entry in its connection-tracking table — this conversation, from this inside address, went
out as this outside address — and the reply at step 3 matched it. For ICMP the entry is keyed on the
echo `id`, which plays the part a port plays in TCP and UDP. **Every NAT is a table of these entries**,
and the next section reads one.

Two consequences follow for anybody reading captures. **A capture taken outside r1 never shows a
private address**: the provider, the far end and anything in between see 203.0.113.2 and nothing else.
And the translation is invisible in the TTL: the reply reached pc1 with `ttl=62`, two fewer than the
64 it left with, because r1 and isp each forwarded it once, rewriting or not. The 21.8 ms is this
lab's virtual machine and says nothing about NAT.
