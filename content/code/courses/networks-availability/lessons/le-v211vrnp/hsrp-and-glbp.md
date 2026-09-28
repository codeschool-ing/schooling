---
title: HSRP and GLBP, Cisco's versions
version: 1
---

VRRP was standardised after Cisco had already shipped its own answer to the same problem, **HSRP**, the
Hot Standby Router Protocol, and a great many networks still run it. None of it was run here: the lab is
Linux, and HSRP and GLBP exist only on Cisco equipment. The ideas are the ones this lesson measured, and
the differences are in the details that bite when two vendors meet or when somebody moves from one to the
other.

| | VRRP | HSRP | GLBP |
|---|---|---|---|
| whose | IETF standard, RFC 3768 and 5798 | Cisco, described in RFC 2281 | Cisco |
| the roles | master and backups | active and standby | one gateway that answers ARP, up to four that forward |
| heartbeat, by default | every 1 s | hello every 3 s, dead after 10 s | hello every 3 s, dead after 10 s |
| virtual MAC | `00-00-5E-00-01-` and the VRID | `0000.0c07.acXX`, the group in hex (version 1) | one per forwarding router |
| taking back after a return | on by default | off by default | off by default for the gateway that answers ARP |
| shares the load | no, one master per group | no, one active per group | yes, within one group |

Three rows deserve a sentence each.

**The timers.** HSRP's defaults, a hello every three seconds and ten seconds before the standby acts, give
a gap of around ten seconds where VRRP's defaults gave 3.264 in this lesson. Both can be lowered, HSRP
down to milliseconds, and lesson 14 said what lowering them costs. The defaults are what a network gets
when nobody has thought about it, which is why they are worth knowing.

**Preemption.** In HSRP a router that comes back does not take over unless it is configured with
`preempt`. People who learned VRRP expect it to, people who learned HSRP expect it not to, and a mixed team
finds out during an outage which assumption the configuration made. The tracking rule at the end of the
previous section is where this matters most.

**The virtual MAC.** HSRP always uses its virtual MAC, so a failover changes no ARP entries at all, the
behaviour VRRP's standard asks for and keepalived's default mode skips. It is also a handy fingerprint:
`0000.0c07.ac0a` in a host's ARP table means the gateway is HSRP group 10.

## Using both routers at once

VRRP and HSRP both leave the backup idle. It is warm, it is ready, and it forwards nothing, which is fine
for resilience and wasteful for a pair of expensive routers. The classic answer is **two groups**: group 1
with `hq` as master for `.1`, group 2 with `hq2` as master for `.4`, and half the hosts told by DHCP to use
`.1` and half `.4`. Each router backs up the other's address. It works, and it doubles the configuration
and splits the hosts by hand.

**GLBP**, the Gateway Load Balancing Protocol, does the splitting itself. One router, the active virtual
gateway, answers every ARP request for the single virtual address, and it answers different hosts with
different virtual MACs, each belonging to one of up to four forwarding routers. Every host has the same
gateway address and, without knowing it, half of them send to one router and half to the other. If a
forwarder dies, another one takes over its MAC.

Two groups with a master on each is the shape lesson 16 uses for load balancers, where it is called
active-active, and it comes with a rule that applies to routers just as much: **each of the two has to be
able to carry everything alone**, or the day one fails the other is overloaded instead of redundant.
