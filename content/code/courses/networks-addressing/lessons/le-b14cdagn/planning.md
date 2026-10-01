---
title: The plan, largest first
version: 1
---

A VLSM plan is four steps, and the order of the last two is what keeps it tidy.

1. List the networks and the hosts each needs, with whatever growth you expect added in.
2. Add two to each and round up to a power of two. The two are the network address and the
   broadcast address, which no host may use. Sales needs 100: 102, rounded up to 128, which is 7 host
   bits and a /25. Engineering's 50 becomes 52 and then 64, a /26. Operations' 20 becomes 22 and
   then 32, a /27. The link's 2 becomes 4, which is already a power of two: a /30.
3. Sort them largest first.
4. Give each the next free address.

The prefix length is 32 minus the number of host bits: 128 addresses is 2⁷, so 7 host bits, so /25.
Rounding is where the plan most often goes wrong. A network of 62 hosts fits a /26 exactly, and a
network of 63 needs 65 addresses and a /25. **Count the two that nobody can use before you round,
not after.**

Step 4 only works because of step 3. A subnet has to start at a multiple of its own size, because its
network address is the one with every host bit at zero. A /26 can start at .0, .64, .128 or .192 and
nowhere else. When the sizes go in from the largest down, each one ends where a smaller one is
allowed to start, so **the subnets pack against each other with no gap between them**. Here is ipcalc
doing exactly that: `-s` takes the host counts and splits the block in the order given.

```
ana@hq1:~$ ipcalc 10.20.32.0/24 -s 100 50 20 2
Address:   10.20.32.0           00001010.00010100.00100000. 00000000
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   10.20.32.0/24        00001010.00010100.00100000. 00000000
HostMin:   10.20.32.1           00001010.00010100.00100000. 00000001
HostMax:   10.20.32.254         00001010.00010100.00100000. 11111110
Broadcast: 10.20.32.255         00001010.00010100.00100000. 11111111
Hosts/Net: 254                   Class A, Private Internet

1. Requested size: 100 hosts
Netmask:   255.255.255.128 = 25 11111111.11111111.11111111.1 0000000
Network:   10.20.32.0/25        00001010.00010100.00100000.0 0000000
HostMin:   10.20.32.1           00001010.00010100.00100000.0 0000001
HostMax:   10.20.32.126         00001010.00010100.00100000.0 1111110
Broadcast: 10.20.32.127         00001010.00010100.00100000.0 1111111
Hosts/Net: 126                   Class A, Private Internet

2. Requested size: 50 hosts
Netmask:   255.255.255.192 = 26 11111111.11111111.11111111.11 000000
Network:   10.20.32.128/26      00001010.00010100.00100000.10 000000
HostMin:   10.20.32.129         00001010.00010100.00100000.10 000001
HostMax:   10.20.32.190         00001010.00010100.00100000.10 111110
Broadcast: 10.20.32.191         00001010.00010100.00100000.10 111111
Hosts/Net: 62                    Class A, Private Internet

3. Requested size: 20 hosts
Netmask:   255.255.255.224 = 27 11111111.11111111.11111111.111 00000
Network:   10.20.32.192/27      00001010.00010100.00100000.110 00000
HostMin:   10.20.32.193         00001010.00010100.00100000.110 00001
HostMax:   10.20.32.222         00001010.00010100.00100000.110 11110
Broadcast: 10.20.32.223         00001010.00010100.00100000.110 11111
Hosts/Net: 30                    Class A, Private Internet

4. Requested size: 2 hosts
Netmask:   255.255.255.252 = 30 11111111.11111111.11111111.111111 00
Network:   10.20.32.224/30      00001010.00010100.00100000.111000 00
HostMin:   10.20.32.225         00001010.00010100.00100000.111000 01
HostMax:   10.20.32.226         00001010.00010100.00100000.111000 10
Broadcast: 10.20.32.227         00001010.00010100.00100000.111000 11
Hosts/Net: 2                     Class A, Private Internet

Needed size:  228 addresses.
Used network: 10.20.32.0/24
Unused:
10.20.32.228/30
10.20.32.232/29
10.20.32.240/28
```

Read it piece by piece: sales is 10.20.32.0/25, hosts .1 to .126; engineering is 10.20.32.128/26,
hosts .129 to .190; operations is 10.20.32.192/27, hosts .193 to .222; the link is
10.20.32.224/30, hosts .225 and .226. The binary column shows each mask moving one more bit to the
right, and each network starting where the last one ended. At the bottom, `Needed size: 228
addresses`, the sum 128 + 64 + 32 + 4, and the 28 addresses left are listed as the three blocks they
fall into: a /30, a /29 and a /28.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"The block 10.20.32.0/24, 256 addresses, drawn as a bar from .0 to .255 with the plan laid on it. Sales, 10.20.32.0/25, takes the first half, .0 to .127, with 126 hosts. Engineering, 10.20.32.128/26, takes .128 to .191, with 62 hosts. Operations, 10.20.32.192/27, takes .192 to .223, with 30 hosts. The last 32 addresses, .224 to .255, are drawn again wider below: the link between r1 and r2, 10.20.32.224/30, then three free blocks, 10.20.32.228/30, 10.20.32.232/29 and 10.20.32.240/28, the last with room for 14 hosts. 228 addresses are planned and 28 are unused.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.32.0/24</text><text x=\"130\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">256 addresses: 228 planned, 28 unused</text><rect x=\"20.0\" y=\"36\" width=\"340.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.32.0/25</text><text x=\"190.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sales, 126 hosts</text><rect x=\"360.0\" y=\"36\" width=\"170.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.32.128/26</text><text x=\"445.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">engineering, 62 hosts</text><rect x=\"530.0\" y=\"36\" width=\"85.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"572.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.192/27</text><text x=\"572.5\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30 hosts</text><rect x=\"615.0\" y=\"36\" width=\"10.62\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"625.62\" y=\"36\" width=\"74.38\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"20.0\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.0</text><text x=\"360.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.128</text><text x=\"530.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.192</text><text x=\"615.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.224</text><text x=\"700.0\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.255</text><line x1=\"615.0\" y1=\"108\" x2=\"300\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"700\" y1=\"108\" x2=\"700\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"300.0\" y=\"150\" width=\"50.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"325.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/30</text><text x=\"325.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">link</text><rect x=\"350.0\" y=\"150\" width=\"50.0\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"375.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/30</text><text x=\"375.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free</text><rect x=\"400.0\" y=\"150\" width=\"100.0\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"450.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.232/29</text><text x=\"450.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free</text><rect x=\"500.0\" y=\"150\" width=\"200.0\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"600.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.240/28</text><text x=\"600.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free, 14 hosts</text><text x=\"300.0\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.224</text><text x=\"350.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.228</text><text x=\"400.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.232</text><text x=\"500.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.240</text><text x=\"700.0\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.255</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the last 32 addresses,</text><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">drawn wider</text></svg>", "caption": "The plan on its /24: largest first, each subnet starting where the previous one ended, and the unused 28 addresses left together at the end."}
```

The order is not decoration. Place the same subnets carelessly and a block that has room can still
fail to hold them. Suppose somebody puts the link at 10.20.32.64/30 and operations at
10.20.32.192/27 first, because those numbers looked tidy. 220 addresses are still free, and sales
needs only 128 of them, but **a /25 can only start at .0 or at .128**, and each of those halves now
has a small subnet sitting inside it. Sales no longer fits anywhere in the block. Largest first
never paints itself into that corner, and the free space it leaves is at the end, in aligned pieces
that a later network can take whole.

Two things a plan written on paper should also say. Rounding up has already given every network some
room: sales has 126 host addresses for 100 hosts, engineering 62 for 50, operations 30 for 20. If a
network will grow past that, plan for the size it will be, because **resizing a subnet later means
renumbering every machine in it**. And the unused space is part of the plan: 10.20.32.240/28 has
room for 14 hosts, and writing that down now is what stops somebody carving it out of the middle of
engineering next year.
