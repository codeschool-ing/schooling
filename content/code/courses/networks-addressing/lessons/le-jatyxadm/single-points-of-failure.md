---
title: Single points of failure, and which ones to keep
version: 1
---

A **single point of failure** is a part whose failure alone takes something down: no twin, no second
path. The campus has a doubled core and doubled uplinks, and it is easy to conclude from the drawing
that it has no single point of failure. Pick any PC and walk up from it, though, and the answer changes.

The lab is built again from scratch, every cable working, and then d1 fails: every one of its
interfaces is set down, which is what a router losing its power looks like to its neighbours. pc1 tries
its own gateway, and then pc2:

```
root@d1:~# for i in eth0 eth1 eth2; do ip link set $i down; done
ana@pc1:~$ ping -c 3 -W 1 10.20.11.1
PING 10.20.11.1 (10.20.11.1) 56(84) bytes of data.

--- 10.20.11.1 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2042ms

ana@pc1:~$ ping -c 3 -W 1 10.20.12.22
PING 10.20.12.22 (10.20.12.22) 56(84) bytes of data.

--- 10.20.12.22 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2052ms

```

**100% packet loss to both.** pc1 cannot reach `10.20.11.1`, the address it sends everything to, so it
reaches nothing beyond its own LAN. Meanwhile c1, c2 and d2 are all healthy, and the core's second path
— the redundancy of the previous section — is sitting there unused, because **the redundancy started
one tier too high**. For pc1, d1 is a single point of failure, and so is everything below it.

Walk up from pc1 and list them:

| part | what its failure takes down | doubled in the lab? |
|---|---|---|
| pc1's cable to a1 | pc1 | no |
| the access switch a1 | everyone on a1 | no |
| d1's cable to a1 | everyone on a1 | no |
| d1, the gateway | everyone on a1, and the LAN's way out | no |
| d1's cables to the cores | nothing: there are two | yes |
| the core routers | nothing: there are two | yes |

## Removing the gateway as a single point

The usual fix for the gateway is **first-hop redundancy**: two distribution routers on pc1's LAN share
one gateway address. One of them, the active router, answers for it; the other listens, and if the
active one goes silent it takes the address over. pc1 keeps sending to the same `10.20.11.1` and never
learns that a different box is answering. The standard protocol for this is **VRRP** (*Virtual Router
Redundancy Protocol*); Cisco's equivalent is HSRP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"First-hop redundancy, as a design not built in the lab. pc1 sends to its gateway, 10.20.11.1, through the access switch a1. That address is not owned by one box: d1, active, answers for it, and a second router on the same LAN stands by to take it over if d1 stops answering. Both routers have cables up to the core.\"><rect x=\"230\" y=\"14\" width=\"260\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c1   c2</text><rect x=\"130\" y=\"100\" width=\"170\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"215\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d1</text><text x=\"215\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">active: answers for it</text><rect x=\"420\" y=\"100\" width=\"170\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"505\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a second router</text><text x=\"505\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">standby: takes it over</text><path d=\"M215 100 L300 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M505 100 L420 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"250\" y=\"176\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">gateway 10.20.11.1</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one address, two routers</text><path d=\"M215 154 L290 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M505 154 L430 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"310\" y=\"236\" width=\"100\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><path d=\"M360 216 L360 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"160\" y=\"236\" width=\"100\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M260 249 L310 249\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "What the lab does not have: a second router sharing pc1's gateway address. With VRRP, the standby router takes the address over when the active one goes silent, and pc1 changes nothing."}
```

**None of this was built in the lab.** The campus scenario has one gateway per LAN precisely so that the
failure above could be shown; a second router and VRRP are what a production design would add. Lesson 22
comes back to gateways, from the side of a switch that routes.

## The ones you keep

Removing every single point of failure is not the goal, and it is not affordable. **Design is deciding
which single points to accept**, and writing the decision down:

- **A desk PC's cable** stays single. A second cable to every desk doubles the cabling for a failure that
  reaches one person, and a technician with a new patch cable fixes it in minutes.
- **An access switch** usually stays single too, with a spare on the shelf. Its failure reaches one
  floor, for as long as it takes to swap it.
- **A server's connection** is often doubled: two network cards to two switches, combined into one link
  (lesson 21 builds that with LACP), because a server's failure reaches everybody who uses it.
- **The gateway and the core** are doubled in almost every network larger than one office, because they
  are the parts whose failure reaches everyone.

The question from lesson 3 holds at every tier: **if this fails, how many people notice?** The answer
says whether the part needs a twin.
