---
title: Longest prefix wins
version: 1
---

The wrong idea comes from firewalls: a routing table is read from the top, and the first line that
matches wins. That is how a list of firewall rules works, and it is not how a routing table works.
**When several routes contain a destination, the one with the longest prefix wins**, wherever it
sits in the list and whenever it was added. The longer prefix says more about the address, so it is
the one that is trusted.

r1 gets two more routes. The whole far network, the /16, goes via ra; one piece of it, 10.30.5.0/24,
goes via rb:

```
root@r1:~# ip route add 10.30.0.0/16 via 10.20.1.2
root@r1:~# ip route add 10.30.5.0/24 via 10.20.2.2
root@r1:~# ip route
default via 10.20.1.2 dev eth1 
10.20.1.0/30 dev eth1 proto kernel scope link src 10.20.1.1 
10.20.2.0/30 dev eth2 proto kernel scope link src 10.20.2.1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
10.30.0.0/16 via 10.20.1.2 dev eth1 
10.30.5.0/24 via 10.20.2.2 dev eth2 
```

For 10.30.5.10, far1's address, three of those lines match: the default, which compares 0 bits; the
/16, which compares 16; and the /24, which compares 24. For 10.30.7.10, far2's, only two do: the
default and the /16, because the third number is 7 and not 5. For 192.0.2.1, nothing but the
default. `ip route get` asks the table the question a packet would ask:

```
root@r1:~# ip route get 10.30.5.10
10.30.5.10 via 10.20.2.2 dev eth2 src 10.20.2.1 uid 0 
    cache 
root@r1:~# ip route get 10.30.7.10
10.30.7.10 via 10.20.1.2 dev eth1 src 10.20.1.1 uid 0 
    cache 
root@r1:~# ip route get 192.0.2.1
192.0.2.1 via 10.20.1.2 dev eth1 src 10.20.1.1 uid 0 
    cache 
```

**10.30.5.10 leaves via rb by the /24; 10.30.7.10 via ra by the /16; 192.0.2.1 via ra by the
default.** The `/24` is printed last in `ip route` and was typed last, and neither fact had anything
to do with it: had it been typed first, the answers would be the same. Traceroute confirms the
packets really go that way, each through a different second hop:

```
ana@pc1:~$ traceroute -n 10.30.5.10
traceroute to 10.30.5.10 (10.30.5.10), 30 hops max, 60 byte packets
 1  10.20.10.1  1.064 ms  0.211 ms  0.137 ms
 2  10.20.2.2  0.911 ms  0.574 ms  0.152 ms
 3  10.30.5.10  1.171 ms  0.637 ms  0.418 ms
ana@pc1:~$ traceroute -n 10.30.7.10
traceroute to 10.30.7.10 (10.30.7.10), 30 hops max, 60 byte packets
 1  10.20.10.1  1.685 ms  0.547 ms  0.386 ms
 2  10.20.1.2  0.336 ms  0.556 ms  0.432 ms
 3  10.30.7.10  1.608 ms  0.439 ms  0.364 ms
```

10.20.2.2 for far1 and 10.20.1.2 for far2, though the two PCs sit on the same network behind the
same switch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Three of r1's routes drawn as nested boxes. The outer box is the default, 0.0.0.0/0, which contains every address and compares 0 bits. Inside it is 10.30.0.0/16, via ra, 16 bits. Inside that is 10.30.5.0/24, via rb, 24 bits. The address 10.30.5.10 sits inside the innermost box and leaves by rb. 10.30.7.10 sits inside the /16 but outside the /24, and leaves by ra. 192.0.2.1 sits only inside the default, and leaves by ra.\"><rect x=\"14\" y=\"12\" width=\"692\" height=\"202\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0.0.0/0</text><text x=\"100\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">default: every address, 0 bits</text><rect x=\"40\" y=\"62\" width=\"640\" height=\"140\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.30.0.0/16</text><text x=\"150\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">via ra, 16 bits</text><rect x=\"66\" y=\"100\" width=\"290\" height=\"88\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"78\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.30.5.0/24</text><text x=\"176\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">via rb, 24 bits</text><circle cx=\"96\" cy=\"155\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"110\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.30.5.10</text><text x=\"110\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leaves by rb</text><circle cx=\"420\" cy=\"145\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"434\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.30.7.10</text><text x=\"434\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leaves by ra</text><circle cx=\"420\" cy=\"37\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"434\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.0.2.1</text><text x=\"434\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leaves by ra, the default</text></svg>", "caption": "Routes nest, and an address leaves by the innermost box that contains it."}
```

The drawing is the rule. Routes nest, because a CIDR prefix either contains another or does not
touch it, and a destination falls through the boxes to the innermost one that contains it. The
default is the box around everything, which is why it only wins when nothing inside it does. **A more specific route is an exception carved out of a broader one**, and that is how they are
used. A summary for a whole site can have one subnet sent another way; a default for the world can
leave the company's own space to more specific routes; and the /24 here steers one part of a network
through a different router.

Two things the rule leaves open. Two routes for exactly the same prefix are the same length, so
length cannot choose between them; the next two sections are about what does. And real routers do this lookup for millions of packets a second. On a router carrying the
internet's routes the table runs to hundreds of thousands of entries, so it is kept in structures
built to find the longest match fast, in hardware on the larger routers. The
answer they reach is the one worked out by hand here.
