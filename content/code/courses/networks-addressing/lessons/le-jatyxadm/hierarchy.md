---
title: Hierarchy, three tiers with one job each
version: 2
---

Lesson 3 ended on a hybrid: stars at the desks, a mesh in the middle. **Hierarchy** is the name for
building that hybrid on purpose, in tiers, where every device belongs to exactly one tier and every
tier has one job. The common picture of "a big network" is a large flat switch with everything
plugged into it. Flat is simple at twenty machines and unmanageable at two thousand, because every
change and every failure touches everybody at once.

The classic design has three tiers:

- **Access** — where the machines plug in. One switch per floor or per room, many ports, cheap. Its
  job is to connect people, and nothing else.
- **Distribution** — the gateway of each access switch's LAN, and the place where rules are applied:
  which LANs may talk, which routes are summarised before they go further up (this lesson's
  scalability section). Each distribution device serves a block of the building.
- **Core** — the middle, which moves traffic between the distribution blocks as fast as it can. **The
  core carries everybody's traffic, so it does no filtering and no clever work**; anything that could
  slow it down or break it belongs a tier lower.

## The campus in the lab

This lesson's network is that design at its smallest: two core
routers, two distribution routers, each distribution router cabled to **both** cores, an access
switch under each distribution router and one PC on each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 384\" role=\"img\" aria-label=\"The campus scenario of the lab in four tiers. Core: c1 and c2, joined by 10.20.0.0/30, c1 at .1 and c2 at .2. Distribution: d1 and d2, each cabled to both cores; c1 to d1 with c1 at .5 and d1 at .6, c1 to d2 with .9 and .10, c2 to d1 with .13 and .14, c2 to d2 with .17 and .18, all in 10.20.0.0/24. Access: the switch a1 under d1, port p24 up to d1, and a2 under d2. Hosts: pc1 at 10.20.11.21 on a1 port p1, in d1's LAN 10.20.11.0/24 with gateway 10.20.11.1; pc2 at 10.20.12.22 on a2, in d2's LAN 10.20.12.0/24 with gateway 10.20.12.1.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">core</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">distribution</text><text x=\"20\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">access</text><text x=\"20\" y=\"344\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hosts</text><path d=\"M290.0 50.0 L450.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"304.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.1</text><text x=\"436.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.2</text><path d=\"M240.0 70.0 L240.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"254.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.5</text><text x=\"254.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.6</text><path d=\"M500.0 70.0 L500.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"514.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.17</text><text x=\"514.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.18</text><path d=\"M287.3 70.0 L452.7 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"303.2\" y=\"88.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.9</text><text x=\"428.2\" y=\"141.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.10</text><path d=\"M452.7 70.0 L287.3 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"436.8\" y=\"88.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.13</text><text x=\"311.8\" y=\"141.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.14</text><path d=\"M240.0 180.0 L240.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500.0 180.0 L500.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M240.0 276.0 L240.0 324.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500.0 276.0 L500.0 324.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"256.0\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p24</text><text x=\"254.0\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><text x=\"516.0\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p24</text><text x=\"514.0\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><rect x=\"190\" y=\"30\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c1</text><rect x=\"450\" y=\"30\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c2</text><rect x=\"190\" y=\"140\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d1</text><text x=\"240.0\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.11.1</text><rect x=\"450\" y=\"140\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d2</text><text x=\"500.0\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.1</text><rect x=\"190\" y=\"236\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><rect x=\"450\" y=\"236\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a2</text><rect x=\"190\" y=\"324\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"338\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"240.0\" y=\"353\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.11.21</text><rect x=\"450\" y=\"324\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"338\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"500.0\" y=\"353\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.22</text><text x=\"570\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.0/24</text><text x=\"310\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.11.0/24</text><text x=\"580\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">links in 10.20.0.0/24,</text><text x=\"580\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one /30 each</text></svg>", "caption": "The campus of lesson 6. The small numbers beside each cable are the last byte of the address at that end, all inside 10.20.0.0/24: 10.20.0.13 is c2's end of the cable to d1, and 10.20.0.18 is d2's end of the cable to c2."}
```

Save it as `~/netlab/campus.sh`:

```bash
# ~/netlab/campus.sh: two core routers, two distribution routers each cabled
# to both cores, and an access switch under each distribution router with one
# PC on it. OSPF with a hello every second; LLDP on every device, so each can
# say who is at the other end of each cable.
#
#        c1 ------------- c2               links: 10.20.0.0/24, one /30 each
#        |  \           / |                pc1's LAN: 10.20.11.0/24 (gateway d1)
#        |    \       /   |                pc2's LAN: 10.20.12.0/24 (gateway d2)
#        d1 -----\ /----- d2
#        |               |
#        a1              a2
#        |               |
#        pc1             pc2
local n
for n in c1 c2 d1 d2; do node $n router; done
for n in a1 a2 pc1 pc2; do node $n; done
link c1 eth1 c2 eth1; addr c1 eth1 10.20.0.1/30;  addr c2 eth1 10.20.0.2/30
link c1 eth2 d1 eth1; addr c1 eth2 10.20.0.5/30;  addr d1 eth1 10.20.0.6/30
link c1 eth3 d2 eth1; addr c1 eth3 10.20.0.9/30;  addr d2 eth1 10.20.0.10/30
link c2 eth2 d1 eth2; addr c2 eth2 10.20.0.13/30; addr d1 eth2 10.20.0.14/30
link c2 eth3 d2 eth2; addr c2 eth3 10.20.0.17/30; addr d2 eth2 10.20.0.18/30
link d1 eth0 a1 p24; link pc1 eth0 a1 p1; switch a1 "p1 p24"
link d2 eth0 a2 p24; link pc2 eth0 a2 p1; switch a2 "p1 p24"
addr d1 eth0 10.20.11.1/24; addr pc1 eth0 10.20.11.21/24; gw pc1 10.20.11.1
addr d2 eth0 10.20.12.1/24; addr pc2 eth0 10.20.12.22/24; gw pc2 10.20.12.1
ospf_p2p c1 10.255.0.1 "eth1 eth2 eth3"; ospf_p2p c2 10.255.0.2 "eth1 eth2 eth3"
ospf_p2p d1 10.255.0.11 "eth1 eth2";     ospf_p2p d2 10.255.0.12 "eth1 eth2"
for n in c1 c2 d1 d2 a1 a2 pc1 pc2; do lldp $n; done
wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.12.22
```

`lldp` starts an LLDP agent on a device, the protocol the section on documentation reads, and the last
line waits until pc1 can reach pc2 across the routers. Build it with
`sudo bash ~/netlab/netlab.sh up campus`, then wait about forty seconds before reading anything, so
every LLDP agent has announced itself to its neighbours at least once.

The routers exchange routes with OSPF, which lesson 16 explains. Here it is useful for one command
that lists, on each router, which neighbours it is talking to. On the core router c1:

```
root@c1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.255.0.2        1 Full/-          52.425s            3.844s 10.20.0.2       eth1:10.20.0.1                       0     0     0
10.255.0.11       1 Full/-          50.430s            3.457s 10.20.0.6       eth2:10.20.0.5                       0     0     0
10.255.0.12       1 Full/-          42.413s            3.819s 10.20.0.10      eth3:10.20.0.9                       0     0     0

```

**Three neighbours**: `10.255.0.2` is c2, the other core; `10.255.0.11` is d1 and `10.255.0.12` is d2,
the two distribution routers. (Those are the routers' OSPF identities, set in `campus.sh`; the
`Address` column is the address at the far end of each cable.) The `Up Time`, from 42.413s to
52.425s, is how long each of those conversations has lasted: the lab was less than a minute old. On
the distribution router d1:

```
root@d1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.255.0.1        1 Full/-          51.607s            3.407s 10.20.0.5       eth1:10.20.0.6                       0     0     0
10.255.0.2        1 Full/-          49.303s            3.671s 10.20.0.13      eth2:10.20.0.14                      0     0     0

```

**Two neighbours, both of them cores.** d1 has no cable to d2. That is the hierarchy's rule written
in cables: a distribution router talks up to the core and down to its access switch, and in this
design not sideways. The access switch a1 runs no routing at all; it is a switch.

Now pc1, at the bottom of one side, reaches pc2 at the bottom of the other:

```
ana@pc1:~$ traceroute -n 10.20.12.22
traceroute to 10.20.12.22 (10.20.12.22), 30 hops max, 60 byte packets
 1  10.20.11.1  2.701 ms  0.358 ms  0.245 ms
 2  10.20.0.13  0.557 ms  0.535 ms  0.230 ms
 3  10.20.0.18  0.485 ms  0.482 ms  0.249 ms
 4  10.20.12.22  1.336 ms  0.459 ms  0.369 ms
```

**Up, across, and down**: `10.20.11.1` is d1, pc1's gateway; `10.20.0.13` is c2, a core router;
`10.20.0.18` is d2; then pc2. The access switches do not appear, because a switch does not answer a
traceroute — it forwards frames without being a hop. Every path between two access blocks has this
shape and this length, whichever block you start in. **Predictable paths are the first thing
hierarchy buys**: anyone who knows the design can tell you where a packet goes before running a
command.

## When three tiers are too many

A small site does not need three tiers of hardware. A **collapsed core** merges core and distribution
into one pair of devices, which is the normal design for a single building of a few hundred people.
The office scenario of lesson 1 is smaller still: one switch, one router, no hierarchy at all, and
correct for its size. The tiers are a way of thinking — what is this device's one job? — before they
are a shopping list.
