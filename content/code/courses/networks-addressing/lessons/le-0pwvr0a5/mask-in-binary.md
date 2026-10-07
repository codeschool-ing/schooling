---
title: A mask is a row of ones
version: 2
---

Lesson 8 said the mask decides where the network part of an address ends. This lesson is the
arithmetic of that, on a lab built for it: one `/24`, `10.20.32.0/24`, cut into three LANs of
different sizes behind the router r1. Lesson 13 is about how that plan was made; this one is about
reading it. Save the lab as `~/netlab/plan.sh` and build it with `sudo bash ~/netlab/netlab.sh up plan`:

```bash
# ~/netlab/plan.sh: one /24 cut into subnets of different sizes, each on its
# own interface of r1, and r2 upstream holding one route for all of them.
#
#   sales1 --(10.20.32.0/25)---+
#   eng1   --(10.20.32.128/26)-+- r1 --(10.20.32.224/30)-- r2 --(10.20.99.0/24)-- hq1
#   ops1   --(10.20.32.192/27)-+
local n
for n in sales1 eng1 ops1 hq1; do node $n; done
node r1 router; node r2 router
link sales1 eth0 r1 eth1; addr sales1 eth0 10.20.32.10/25;  addr r1 eth1 10.20.32.1/25
link eng1 eth0 r1 eth2;   addr eng1 eth0 10.20.32.140/26;  addr r1 eth2 10.20.32.129/26
link ops1 eth0 r1 eth3;   addr ops1 eth0 10.20.32.200/27;  addr r1 eth3 10.20.32.193/27
gw sales1 10.20.32.1; gw eng1 10.20.32.129; gw ops1 10.20.32.193
link r1 eth0 r2 eth0; addr r1 eth0 10.20.32.225/30; addr r2 eth0 10.20.32.226/30
gw r1 10.20.32.226
link r2 eth1 hq1 eth0; addr r2 eth1 10.20.99.1/24; addr hq1 eth0 10.20.99.10/24; gw hq1 10.20.99.1
ip -n r2 route add 10.20.32.0/24 via 10.20.32.225
```

Every mask in this lesson is in an `addr` line of that file, and r2's single route for all three LANs
is its last line.

The shape first. **A subnet mask is 32 bits: a run of ones, then a run of zeros, and nothing else.**
The ones cover the network part of the address and the zeros cover the host part. The machine
sales1 has a mask that does not fall on a dot:

```
ana@sales1:~$ ip -br addr show eth0
eth0@if173       UP             10.20.32.10/25 fe80::9d:2ff:fe68:6e19/64 
ana@sales1:~$ ipcalc 10.20.32.10/25
Address:   10.20.32.10          00001010.00010100.00100000.0 0001010
Netmask:   255.255.255.128 = 25 11111111.11111111.11111111.1 0000000
Wildcard:  0.0.0.127            00000000.00000000.00000000.0 1111111
=>
Network:   10.20.32.0/25        00001010.00010100.00100000.0 0000000
HostMin:   10.20.32.1           00001010.00010100.00100000.0 0000001
HostMax:   10.20.32.126         00001010.00010100.00100000.0 1111110
Broadcast: 10.20.32.127         00001010.00010100.00100000.0 1111111
Hosts/Net: 126                   Class A, Private Internet

```

`/25` is twenty-five ones, and ipcalc shows them: three octets of `11111111` and then one more 1, at the
start of the fourth octet. Written in decimal that fourth octet is `10000000`, which is 128, so the
mask is `255.255.255.128`. The space ipcalc prints falls after the twenty-fifth bit this time, in the
middle of an octet, and that is the moment the four-fields picture of lesson 8 stops working: the
last octet of `10.20.32.10` is partly network and partly host.

**Finding the network is a bitwise AND of the address and the mask.** Where the mask has a 1, the
address bit is kept; where it has a 0, the bit becomes 0. The first three octets have a mask of 255,
all ones, so they come through unchanged as `10.20.32`. The interesting octet is the last:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"The address 10.20.32.10 with the mask 255.255.255.128, last octet bit by bit. The first three octets have a mask of 255 and are copied as they are, 10.20.32. Address .10 is 00001010. Mask .128 is 10000000. The AND of the two, bit by bit, is 00000000: network .0. Setting the 7 host bits to 1 gives 01111111: broadcast .127. A dashed line after the first bit of the octet, bit 25 of the address, marks where the network part ends.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">octets 1 to 3: mask 255, copied as they are: 10.20.32</text><text x=\"322\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bit 25</text><text x=\"504\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">7 host bits</text><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">address, .10</text><rect x=\"300\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"319\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"350\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"369\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"394\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"413\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"438\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"482\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"526\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"570\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"614\" y=\"58\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"633\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><text x=\"20\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mask, .128</text><rect x=\"300\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"319\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"350\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"369\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"394\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"413\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"438\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"482\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"526\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"570\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"614\" y=\"104\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"633\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><path d=\"M300 146 L656 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">AND: network, .0</text><rect x=\"300\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"319\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"350\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"369\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"394\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"413\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"438\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"482\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"526\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"570\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"614\" y=\"150\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"633\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><text x=\"20\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">host bits all 1: broadcast, .127</text><rect x=\"300\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"319\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">0</text><rect x=\"350\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"369\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"394\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"413\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"438\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"482\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"526\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"570\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"614\" y=\"196\" width=\"38\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"633\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><path d=\"M341 52 L341 248\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "Where the mask has a 1 the address bit is kept; where it has a 0 the bit is cleared. What is left is the network, 10.20.32.0/25."}
```

`10` is `00001010` and the mask's `128` is `10000000`. Only the first bit is kept, and it is 0, so the
result is `00000000`: the network is `10.20.32.0/25`, as ipcalc's `Network` line says. Set the seven
host bits to 1 instead and you get `01111111`, 127: the broadcast address `10.20.32.127`. Between the
two lie `HostMin` `.1` to `HostMax` `.126`, which is the `Hosts/Net: 126` on the last line.

**Because a mask is ones followed by zeros, an octet of a mask can take only nine values**: 0, 128,
192, 224, 240, 248, 252, 254 and 255, which are zero to eight ones filled in from the left. Anything
else is not a mask. `255.255.255.100` is a typing mistake, since 100 is `01100100`, and so is
`255.255.0.255`, which has a zero before a one. Learning the nine values by heart saves converting
every mask you meet.

ipcalc printed one more line, `Wildcard: 0.0.0.127`. It is the mask turned inside out, ones where the
mask has zeros, and some router configurations, Cisco's access lists and OSPF among them, ask for it
instead of the mask. **Wildcard plus mask is always 255 in every octet**, so one is 255 minus the
other: 255 − 128 = 127.

The last line still says `Class A, Private Internet`, as it did in lesson 8. sales1's network is a
`/25` inside the old class A space. The class said `/8`, the mask says `/25`, and the mask is the one
every machine in this lab obeys.
