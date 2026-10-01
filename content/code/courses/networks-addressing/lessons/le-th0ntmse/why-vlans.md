---
title: One switch, several networks
version: 1
---

Lesson 18 ended on a rule: a switch sends a broadcast out of every port, so everything plugged
into it is one broadcast domain, and only a router ends one. The usual conclusion is that two
departments that must not share a broadcast domain need two switches. They do not. **A VLAN
(*virtual LAN*) is a broadcast domain drawn in the switch's configuration instead of in its
cables**: each port is given a VLAN number, and a frame that enters in VLAN 10 can only leave by a
port in VLAN 10. One switch becomes several, and nothing is unplugged.

The lab for this lesson is two switches, sw1 and sw2, joined by one cable between their ports
p24, and five PCs. pc1 and pc3 belong to one department and have addresses in 10.20.10.0/24; pc2
and pc4 belong to another, in 10.20.20.0/24. pc5 is the odd one: its address is in the first
department's range, and its port will be put in the second department's VLAN, which is the
experiment of the last section. The switches are the Linux kernel's bridge with VLAN filtering
switched on, configured with the `bridge vlan` command. A commercial switch says the same things in
its own words, and the lesson names those words where they differ.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The lab for lesson 19. Switch sw1 has pc1 on port p1, address 10.20.10.21, in VLAN 10, and pc2 on port p2, address 10.20.20.22, in VLAN 20. Switch sw2 has pc3 on p1, 10.20.10.23, VLAN 10; pc4 on p2, 10.20.20.24, VLAN 20; and pc5 on p3, 10.20.10.25, VLAN 20. The two switches are joined by one cable from p24 to p24, which becomes the trunk. pc5&#x27;s address is in VLAN 10&#x27;s subnet while its port is in VLAN 20.\"><defs><marker id=\"v19t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"84\" x2=\"135\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.21</text><text x=\"32\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"143\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><line x1=\"230\" y1=\"84\" x2=\"215\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"170\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"182\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.20.22</text><text x=\"182\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"207\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><line x1=\"390\" y1=\"84\" x2=\"475\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"330\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"342\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"342\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.23</text><text x=\"342\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"483\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><line x1=\"520\" y1=\"84\" x2=\"525\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"460\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"472\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"472\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.20.24</text><text x=\"472\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"533\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><line x1=\"650\" y1=\"84\" x2=\"575\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"590\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc5</text><text x=\"602\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">10.20.10.25</text><text x=\"602\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"567\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><line x1=\"255\" y1=\"192\" x2=\"445\" y2=\"192\" stroke=\"var(--paper)\" stroke-width=\"3\"></line><rect x=\"95\" y=\"170\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"445\" y=\"170\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"175\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><text x=\"525\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw2</text><text x=\"262\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p24</text><text x=\"438\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p24</text><text x=\"350\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one cable</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pc5's address is in VLAN 10's subnet; its port is in VLAN 20.</text><text x=\"20\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Port VLANs as this lesson configures them. Before that, every port is in VLAN 1.</text></svg>", "caption": "The lab for this lesson: two switches joined at p24, five PCs and two departments. pc5 is the deliberate mistake, with an address from one department and a port in the other department's VLAN."}
```

Before anything is configured, every port is in **VLAN 1, the default VLAN** that almost every
switch ships with:

```
root@sw1:~# bridge vlan show
port              vlan-id  
p1                1 PVID Egress Untagged
p2                1 PVID Egress Untagged
p24               1 PVID Egress Untagged
br0               1 PVID Egress Untagged
```

Each line is a port and the VLANs it belongs to. `PVID` marks the VLAN an untagged frame arriving
on that port is put in, and `Egress Untagged` says frames of that VLAN leave the port without a
tag; the next three sections take both words apart. `br0` is the switch itself, the interface it
would use if it had an address of its own. All four lines say the same thing: one VLAN, and
everybody in it.

So pc2, in the other department, hears what pc1 says to pc3. pc1 pinged pc3 while pc2 ran
`tcpdump` in a second terminal, which is why tcpdump's output comes after the ping:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 8.756/8.756/8.756/0.000 ms
root@pc2:~# timeout 6 tcpdump -n -e -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:00:09.729306 02:25:70:bc:29:c6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.10.23 tell 10.20.10.21, length 28

1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

The ARP request went to `ff:ff:ff:ff:ff:ff`, and pc2 received it although nothing on pc2 has
anything to do with 10.20.10.23. On five PCs that is one line of output. On a floor of a few
hundred machines, every ARP question, every DHCP request and every printer announcing itself
reaches all of them, and every network card has to take the frame in and every operating system
has to look at it before throwing it away. Everybody can also see who is asking for whom, which a
department in a different position of trust has no business seeing.

That gives three reasons to split a network, and each is a different kind of reason. The first is
size: **broadcast traffic grows with the number of machines in the domain**, so a domain is kept
small enough that its chatter stays background. The second is control: traffic between two VLANs
has to pass through a router, and a router is a place where a rule can say who may talk to whom,
which is lesson 22. The third is organisation: a VLAN follows a function rather than a desk, so the
finance VLAN can exist on every floor and every switch without a cable of its own.

What a VLAN does not do is just as important. It encrypts nothing, and it does not decide who
may plug in — that is port security and 802.1X, from lesson 18. **The convention this lab follows
is one VLAN per IP subnet**: 10.20.10.0/24 lives in VLAN 10 and 10.20.20.0/24 in VLAN 20, so the
broadcast domain and the subnet are the same set of machines. pc5 breaks that convention on
purpose, and the last section shows what happens when the address says one thing and the port
says another.
