---
title: Reading a routing table
version: 1
---

The usual picture of a router is a box that knows the network: it can see where things are and
finds a way there. It does not. **A router knows its routing table and nothing else.** For every
packet it reads the destination address, looks for the entries in the table that contain it, and
sends the packet where the winning entry says: out of an interface, and usually to a next router.
If no entry contains the address, the packet goes nowhere, however close the destination is.

This lesson's lab makes that visible. r1 has two cables out, one to ra and one to rb, and both of
those sit on the far network, 10.30.0.0/16, where far1 and far2 live. Nothing is routed
dynamically: every route in the lesson is typed by hand, which is lesson 15's subject, and lesson
16 hands the job to protocols.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The lab for this lesson. pc1, 10.20.10.21, is cabled to the router r1, which is 10.20.10.1 on eth0. r1 has two more cables: eth1, 10.20.1.1, on the link 10.20.1.0/30 to the router ra at 10.20.1.2; and eth2, 10.20.2.1, on the link 10.20.2.0/30 to the router rb at 10.20.2.2. ra (10.30.0.1) and rb (10.30.0.2) both sit on the far network, 10.30.0.0/16, where far1 is 10.30.5.10 and far2 is 10.30.7.10.\"><rect x=\"20\" y=\"100\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.21</text><line x1=\"140\" y1=\"125\" x2=\"190\" y2=\"125\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"190\" y=\"72\" width=\"124\" height=\"106\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"200\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">router</text><text x=\"200\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth0 10.20.10.1</text><text x=\"200\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth1 10.20.1.1</text><text x=\"200\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth2 10.20.2.1</text><line x1=\"314\" y1=\"106\" x2=\"440\" y2=\"55\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><line x1=\"314\" y1=\"144\" x2=\"440\" y2=\"195\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"352\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/30</text><text x=\"352\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.0/30</text><rect x=\"440\" y=\"24\" width=\"96\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ra</text><text x=\"450\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.2</text><text x=\"450\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.0.1</text><line x1=\"536\" y1=\"55\" x2=\"572\" y2=\"55\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"440\" y=\"164\" width=\"96\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rb</text><text x=\"450\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.2</text><text x=\"450\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.0.2</text><line x1=\"536\" y1=\"195\" x2=\"572\" y2=\"195\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"572\" y=\"14\" width=\"138\" height=\"222\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"584\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the far network</text><text x=\"584\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.0.0/16</text><rect x=\"584\" y=\"80\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"594\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">far1</text><text x=\"594\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.5.10</text><rect x=\"584\" y=\"132\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"594\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">far2</text><text x=\"594\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.7.10</text></svg>", "caption": "The lab for this lesson: r1 has two ways to the far network, through ra and through rb, and starts knowing neither."}
```

This is r1's table before anybody has typed anything, followed by pc1 trying to reach far1:

```
root@r1:~# ip route
10.20.1.0/30 dev eth1 proto kernel scope link src 10.20.1.1 
10.20.2.0/30 dev eth2 proto kernel scope link src 10.20.2.1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
ana@pc1:~$ ping -c 1 -W 1 10.30.5.10
PING 10.30.5.10 (10.30.5.10) 56(84) bytes of data.
From 10.20.10.1 icmp_seq=1 Destination Net Unreachable

--- 10.30.5.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

Three lines, one per interface with an address. Take the first apart:

| part | what it says |
|---|---|
| `10.20.1.0/30` | the destination, a prefix: every address whose first 30 bits match |
| `dev eth1` | the interface a matching packet leaves by |
| `proto kernel` | who put the route there: the kernel, the moment the address 10.20.1.1/30 was set |
| `scope link` | the destination is on that cable itself, so no other router is needed |
| `src 10.20.1.1` | the address r1 uses as the source of packets it sends there itself |

These are **connected routes**, and they are the only kind a router has without being told
anything. They have no `via`: to reach 10.20.1.2, r1 asks ARP for 10.20.1.2's own hardware address
and sends the frame straight to it. A route that names a next hop, with `via`, is the other kind,
and the next section adds the first one.

Then pc1's ping. pc1 has a default route to r1, so it sent the packet; r1 looked for an entry
containing 10.30.5.10, found none, and dropped it. **`From 10.20.10.1 ... Destination Net
Unreachable` is r1 saying so**, in an ICMP message back to pc1. The address at the start of the
line is the router that gave up, which is the first thing to read in it: not far1, which never saw
the packet, and not pc1, which had a route and used it. A host with no route of its own prints
`Network is unreachable` without sending anything, as the networks course showed; this message
came from one hop away.

r1 is cabled to the two routers that could reach far1, a metre of cable from the answer, and it
still knows nothing about 10.30.0.0/16. **Being connected to a router that knows the way is not
knowing the way.** Every route beyond the router's own cables arrives in one of two ways: somebody
types it, or a routing protocol learns it from a neighbour. Either way it ends up as a line in this
table, and the next four sections are about which line wins when more than one could.
