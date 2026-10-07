---
title: Why routers tell each other
version: 2
---

Lesson 15 ended with r3 sending replies towards a cable that no longer existed, because nothing could
tell it. **A routing protocol is routers telling each other what they can reach**, all the time, so that
a change anywhere reaches every table. This lesson's lab is four routers in a ring, the shape lesson 3
used, with a PC behind r1 and another behind r2:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The lab for this lesson: four routers in a ring. r1 and r2 are joined by 10.20.0.0/30 (r1 10.20.0.1, r2 10.20.0.2); r2 and r3 by 10.20.0.4/30 (r2 10.20.0.5, r3 10.20.0.6); r3 and r4 by 10.20.0.8/30 (r3 10.20.0.9, r4 10.20.0.10); r4 and r1 by 10.20.0.12/30 (r4 10.20.0.13, r1 10.20.0.14). pc1, 10.20.1.10, is on 10.20.1.0/24 behind r1 at 10.20.1.1; pc2, 10.20.2.10, is on 10.20.2.0/24 behind r2 at 10.20.2.1.\"><defs><marker id=\"rg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"200\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.0.1</text><text x=\"200\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth4 10.20.0.14</text><text x=\"200\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.1.1</text><rect x=\"430\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"440\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.0.2</text><text x=\"440\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.0.5</text><text x=\"440\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.2.1</text><rect x=\"430\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"440\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.0.6</text><text x=\"440\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.0.9</text><rect x=\"190\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><text x=\"200\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.0.10</text><text x=\"200\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth4 10.20.0.13</text><rect x=\"20\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"590\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"600\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.10</text><path d=\"M130 95 L190 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M560 95 L590 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 95 L430 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M495 130 L495 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 245 L430 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M255 130 L255 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"375\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.0/30</text><text x=\"505\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.4/30</text><text x=\"375\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.8/30</text><text x=\"245\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.12/30</text><text x=\"160\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"645\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.0/24</text></svg>", "caption": "The lab for this lesson: lesson 3's ring, with no routing protocol until one is typed."}
```

It is lesson 3's ring with no routing protocol in it. Save it as `~/netlab/igp.sh` and build it with
`sudo bash ~/netlab/netlab.sh up igp`:

```bash
# ~/netlab/igp.sh: the ring of ring.sh with no routing protocol configured.
# FRR runs on every router with only its hostname, and the RIP, OSPF and
# EIGRP daemons are started, waiting for a configuration.
local n
for n in r1 r2 r3 r4; do node $n router; done
node pc1; node pc2
link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
for n in r1 r2 r3 r4; do echo "hostname $n" | FRR_EXTRA="ripd ospfd eigrpd" frr $n; done
```

The last line starts FRR on each router with nothing but its name, and with the RIP, OSPF and EIGRP
daemons running, waiting for the configuration this lesson types into `vtysh`.

Nothing is configured yet beyond the addresses. r1 knows its three cables and nothing more, and pc1
cannot reach pc2:

```
root@r1:~# ip route
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 
10.20.0.12/30 dev eth4 proto kernel scope link src 10.20.0.14 
10.20.1.0/24 dev eth0 proto kernel scope link src 10.20.1.1 
ana@pc1:~$ ping -c 1 -W 1 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.
From 10.20.1.1 icmp_seq=1 Destination Net Unreachable

--- 10.20.2.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 1ms

```

You could fix this with static routes. Count what it takes: the ring has six networks, and each router
needs a route to every network it is not on. r1 and r2 touch three each and need three routes each; r3
and r4 touch two each and need four each. **Fourteen typed routes**, and every one of them points one way
round the ring with no idea what to do when a cable fails. Add a fifth router and you visit all of them
again.

## Two ways to tell

Routing protocols inside one organisation are called **interior gateway protocols**, IGPs. They come in
two families, and the difference is what a router tells its neighbours:

- *Distance vector.* Each router tells its neighbours its own table: *these networks, at these
  distances*. A neighbour adds the cost of the link between them and keeps the best offer. Nobody sees
  the whole network; each router trusts what the next one says. **RIP** works this way.
- *Link state.* Each router tells *every* router in the area about its own links: *I am r1, I have a
  cable to r2 and one to r4, and this LAN*. Every router collects the same set of descriptions, draws
  the same map, and calculates its own shortest paths over it. **OSPF** works this way, and so does
  IS-IS, which large providers use and this course does not cover.

**EIGRP**, the third protocol here, is distance vector with extra bookkeeping: it remembers what every
neighbour offered, so it can switch to a backup without asking anybody.

## What they all share

Each protocol finds its **neighbours** first, by sending small hello messages out of the interfaces it
was told to use, and only exchanges routes with routers that answer. Each one puts its best routes in the
same kernel table lesson 14 read, marked with its name, `proto rip` or `proto ospf`. Each also carries
the **administrative distance** lesson 14 listed, so that a router running two of them knows whose route to
believe: 120 for RIP, 110 for OSPF, and 90 for EIGRP's internal routes on Cisco equipment.

The other thing they share is that they are **interior**. They assume every router is run by the same
people and tells the truth. Between organisations, where that assumption fails, the internet uses BGP,
which is lesson 17.

In the lab, every router runs FRR, the same routing software lesson 14 used to show administrative
distance, with every daemon this lesson needs already started and nothing configured. Each protocol is
typed on r1 and shown there; the same lines were typed on r2, r3 and r4 without being shown.
