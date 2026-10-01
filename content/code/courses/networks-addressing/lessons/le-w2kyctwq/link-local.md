---
title: fe80, the address every interface gives itself
version: 1
---

In IPv4 an interface has no address until somebody or something gives it one. **In IPv6 every
interface gives itself a link-local address the moment it comes up**, with no server and no
configuration. Link-local addresses live in `fe80::/10` (in practice always `fe80::/64`), they are
valid only on their own link, and no router forwards them. They exist so that machines on one cable
can always talk to each other, which IPv6 needs before anything else works: the next two sections
show a router advertising itself and a neighbour being found, both from link-local addresses.

pc1's card and its link-local address:

```
ana@pc1:~$ ip link show eth0
28: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
ana@pc1:~$ ip -6 addr show eth0 scope link
28: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 fe80::25:70ff:febc:29c6/64 scope link 
       valid_lft forever preferred_lft forever
```

The MAC address is `02:25:70:bc:29:c6` and the link-local address is `fe80::25:70ff:febc:29c6`. The
digits of the MAC are in there, nearly all of them. **Linux built the interface identifier from the
MAC by a rule called modified EUI-64**:

1. split the six bytes of the MAC in half: `02:25:70` and `bc:29:c6`;
2. put `ff:fe` in the middle, which makes eight bytes, 64 bits;
3. flip the seventh bit of the first byte, the one that says whether a MAC was assigned by a
   manufacturer or locally.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"How pc1 built its link-local address from its MAC address, in three steps. First, the MAC address 02:25:70:bc:29:c6, drawn as six bytes with a gap in the middle. Second, ff and fe are inserted in the gap, giving eight bytes: 02, 25, 70, ff, fe, bc, 29, c6. Third, bit 7 of the first byte is flipped, so 02, binary 00000010, becomes 00, binary 00000000, giving 00, 25, 70, ff, fe, bc, 29, c6. Those 64 bits after fe80::/64 make the link-local address fe80::25:70ff:febc:29c6.\"><text x=\"20\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pc1's MAC address</text><rect x=\"290\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">02</text><rect x=\"340\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"390\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"540\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"590\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"640\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"662\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"20\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">insert ff:fe in the middle</text><rect x=\"290\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">02</text><rect x=\"340\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"390\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"440\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ff</text><rect x=\"490\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">fe</text><rect x=\"540\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"590\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"640\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"662\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">flip bit 7 of the first byte</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00000010 → 00000000</text><rect x=\"290\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">00</text><rect x=\"340\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"390\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"440\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ff</text><rect x=\"490\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">fe</text><rect x=\"540\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"590\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"640\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"662\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the link-local address</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fe80::/64 + the 64-bit identifier</text><text x=\"290\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\">fe80::25:70ff:febc:29c6</text></svg>", "caption": "Modified EUI-64: the MAC split in half, ff:fe in the gap, one bit flipped. The leading zeros of 0025 are then dropped, as in any group."}
```

The first byte here is `02`, binary `00000010`, and the seventh bit is the 1 in it, so flipping it
gives `00`. The lab gives its machines MACs starting with `02`, the mark of a locally administered
address. A MAC burnt in by a manufacturer has that bit at 0, and the flip turns it into 1: a card
whose MAC starts `00:1a` gets an identifier starting `021a`. **The `ff:fe` in the middle is the
fingerprint**: an IPv6 address with `ff:fe` in the fourth and fifth bytes of its identifier was
built from a MAC.

That fingerprint is also a privacy problem. A laptop that builds every address from its MAC carries
the same 64 bits from network to network, and anybody who sees its addresses can follow it. Many
systems now build the identifier of their global addresses from random bits instead. In this lab
Linux used EUI-64, which is why the arithmetic is visible.

Now try to reach r1 by its link-local address:

```
root@r1:~# ip -6 addr show eth0 scope link
34: eth0@if33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 fe80::1f:23ff:fee7:e9d5/64 scope link 
       valid_lft forever preferred_lft forever
ana@pc1:~$ ping -c 1 fe80::1f:23ff:fee7:e9d5
ping: Warning: IPv6 link-local address on ICMP datagram socket may require ifname or scope-id => use: address%<ifname|scope-id>
PING fe80::1f:23ff:fee7:e9d5 (fe80::1f:23ff:fee7:e9d5) 56 data bytes

--- fe80::1f:23ff:fee7:e9d5 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@pc1:~$ ping -c 1 fe80::1f:23ff:fee7:e9d5%eth0
PING fe80::1f:23ff:fee7:e9d5%eth0 (fe80::1f:23ff:fee7:e9d5%eth0) 56 data bytes
64 bytes from fe80::1f:23ff:fee7:e9d5%eth0: icmp_seq=1 ttl=64 time=2.44 ms

--- fe80::1f:23ff:fee7:e9d5%eth0 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 2.436/2.436/2.436/0.000 ms
```

The first ping printed a warning and lost its packet. The second added `%eth0` and got an answer.
The difference is the whole point of a link-local address: **every interface has one in
`fe80::/64`, so the address alone does not say which link to send the packet on**. A machine with
two cards has two links that both contain `fe80::1f:23ff:fee7:e9d5` as far as its routing is
concerned. `%eth0` is the **zone**, the interface the address belongs to, and the warning ping
printed says exactly that, `use: address%<ifname|scope-id>`. Global addresses never need a zone;
link-local ones do, whenever a program has to be told one.

r1's own link-local address, `fe80::1f:23ff:fee7:e9d5`, came from its MAC `02:1f:23:e7:e9:d5` by the
same three steps. Remember it: in the next section it turns up as the default gateway of every PC in
the office.
