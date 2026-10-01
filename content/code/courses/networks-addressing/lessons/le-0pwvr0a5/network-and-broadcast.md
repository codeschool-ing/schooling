---
title: The first and last address of a range
version: 1
---

Every range has two addresses that belong to it and to no machine. **The network address has every
host bit at 0, and the broadcast address has every host bit at 1.** Everything between them is
available for machines. Given any address and its prefix, both ends can be found, and this section
does it for eng1, which sits in the middle LAN of the lab:

```
ana@sales1:~$ ipcalc -b 10.20.32.140/26
Address:   10.20.32.140         
Netmask:   255.255.255.192 = 26 
Wildcard:  0.0.0.63             
=>
Network:   10.20.32.128/26      
HostMin:   10.20.32.129         
HostMax:   10.20.32.190         
Broadcast: 10.20.32.191         
Hosts/Net: 62                    Class A, Private Internet

```

Work it by hand before reading the answer off ipcalc. `/26` is 26 ones, so the mask's last octet is
`11000000`, 192, and the last octet holds 2 network bits and 6 host bits. The address's last octet is
140, which is `10001100`.

- **Network**: keep the 2 network bits, clear the 6 host bits. `10001100` becomes `10000000`, 128,
  so the network is `10.20.32.128`.
- **Broadcast**: keep the 2 network bits, set the 6 host bits. `10111111`, 191, so the broadcast is
  `10.20.32.191`.
- **Hosts**: everything between, `10.20.32.129` to `10.20.32.190`.

ipcalc agrees on all three, and its `Hosts/Net: 62` is the count of that last range. In the lab, r1's
`eth2` holds `10.20.32.129`, the first host address, and eng1 holds `.140`. **Giving the gateway the
first usable address is a convention, not a rule**: it makes the gateway easy to guess, and this lab
follows it on all three LANs.

ops1's LAN, the `/27` from the previous section, works the same way. The mask's last octet is 224,
`11100000`, three network bits and five host bits. 200 is `11001000`; clearing the five host bits
gives `11000000`, 192, and setting them gives `11011111`, 223. ipcalc's `Network: 10.20.32.192/27` and
`Broadcast: 10.20.32.223` say the same.

There is a pattern in those answers that the bits make hard to see. Drawn on a line, the last octet
runs from 0 to 255, and a prefix cuts it into equal blocks:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"The last octet of 10.20.32.x drawn as a line from 0 to 256, cut three ways. Cut into blocks of 128 for /25, the block .0–.127 is highlighted, holding sales1 at .10. Cut into blocks of 64 for /26, the block .128–.191 is highlighted, holding eng1 at .140. Cut into blocks of 32 for /27, the block .192–.223 is highlighted, holding ops1 at .200. Every block starts at a multiple of its own size.\"><text x=\"40\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/25: blocks of 128</text><rect x=\"41\" y=\"34\" width=\"318\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.0–.127</text><rect x=\"361\" y=\"34\" width=\"318\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M65 64 L65 74\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"69\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sales1 .10</text><text x=\"40\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/26: blocks of 64</text><rect x=\"41\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"201\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"361\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"366\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.128–.191</text><rect x=\"521\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M390 140 L390 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"394\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">eng1 .140</text><text x=\"40\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/27: blocks of 32</text><rect x=\"41\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"121\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"201\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"281\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"361\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"441\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"521\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.192–.223</text><rect x=\"601\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M540 216 L540 226\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"536\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ops1 .200</text><path d=\"M40 246 L40 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M120 246 L120 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><path d=\"M200 246 L200 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><path d=\"M280 246 L280 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"280\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">96</text><path d=\"M360 246 L360 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">128</text><path d=\"M440 246 L440 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">160</text><path d=\"M520 246 L520 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192</text><path d=\"M600 246 L600 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">224</text><path d=\"M680 246 L680 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">256</text><text x=\"40\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the last octet of 10.20.32.x</text></svg>", "caption": "The three LANs of this lab on one ruler. A prefix fixes the block size, and the block an address falls in is its network."}
```

**Every range starts at a multiple of its own size.** A `/26` has 64 addresses, so the `/26` networks in
a `/24` start at 0, 64, 128 and 192; 140 is between 128 and 191, so its network is `.128`. A `/27` has
32 addresses, so its networks start at multiples of 32; 200 falls in 192 to 223. Once that is
clear, the bit work in the list above is a check rather than the method, and the section on working
by hand turns the pattern into a procedure that takes seconds.

The rule also says which ranges cannot exist. `10.20.32.100/26` is a host address, not a network: the
`/26` network containing it is `10.20.32.64`. Somebody who writes `10.20.32.100/26` in a plan meaning a
network has made a mistake that ipcalc would show at once in its `Network` line. **A network address
is one whose host bits are all zero**, and a quick test of any plan is to check that each network
listed in it really is one.
