---
title: Why the offices cannot talk
version: 1
---

The lab has two offices. At head office, `laptop` sits on `192.168.10.0/24` behind the router `hq`. At
the branch, a till, `till`, sits on `192.168.20.0/24` behind the router `branch`. Each router has one
public address, and between them is an ISP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 180\" role=\"img\" aria-label=\"Five machines in a row: laptop at 192.168.10.20 on the office LAN, the office router hq at 203.0.113.2, the ISP router at 203.0.113.1, the branch router at 198.51.100.2 and the till at 192.168.20.30 on the branch LAN. A dashed line joins hq and branch over the ISP: the tunnel, tun0, from 10.0.0.1 to 10.0.0.2. The ISP routes only public addresses, so 192.168.x.x has nowhere to go without it.\"><defs><marker id=\"topo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"75.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"170\" y=\"40\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"230.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"330\" y=\"40\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"385.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"385.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.1</text><rect x=\"480\" y=\"40\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"540.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><rect x=\"640\" y=\"40\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"690.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">till</text><text x=\"690.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M130 62 L170 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M290 62 L330 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M440 62 L480 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 62 L640 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"75\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">office LAN</text><text x=\"385\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the internet</text><text x=\"690\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">branch LAN</text><path d=\"M230 84 C 250 140, 520 140, 540 84\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#topo-ah)\"></path><text x=\"385\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tun0: 10.0.0.1 to 10.0.0.2</text><text x=\"385\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the ISP routes only public addresses: 192.168.x.x has nowhere to go</text></svg>", "caption": "The lab's two offices. Every tunnel in lessons 1 to 5 is drawn between hq and branch, or from a laptop at home to hq."}
```

Each office reaches the internet through NAT, which lesson 11 of `networks-addressing` covered: `hq`
rewrites the source of everything leaving to its own public address. That works for a conversation that
starts inside. It does nothing for a conversation from one private network to another, and a ping from
the laptop to the till shows it:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1015ms

ana@laptop:~$ traceroute -n -w 1 -q 1 -m 4 192.168.20.30
traceroute to 192.168.20.30 (192.168.20.30), 4 hops max, 60 byte packets
 1  192.168.10.1  0.054 ms
 2  *
 3  *
 4  *
```

The first hop, `hq`, answers. After that there is silence, and the ISP's routing table says why:

```
ana@isp:~$ ip route
192.0.2.0/24 dev eth2 proto kernel scope link src 192.0.2.1 
198.51.100.0/24 dev eth1 proto kernel scope link src 198.51.100.1 
203.0.113.0/24 dev eth0 proto kernel scope link src 203.0.113.1 
```

**The ISP knows three public networks and no private one.** A packet for `192.168.20.30` matches none
of its routes, so the ISP drops it. That is not a fault of this ISP. The ranges in RFC 1918 are private
because thousands of companies use the same ones, and no router on the internet could know which
`192.168.20.30` a packet meant.

The routers at the two ends do know. `hq` knows the till is behind `branch`, and `branch` knows it can
reach `hq` at `203.0.113.2`. What is missing is a way to hand the packet from one to the other across a
network that will only carry public addresses, which is what a tunnel is for.
