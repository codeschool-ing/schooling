---
title: Dual stack, two protocols on one cable
version: 1
---

Moving to IPv6 does not mean switching IPv4 off on a chosen day. **The way nearly every network
runs IPv6 today is dual stack**: both protocols on the same interfaces, side by side, each with its
own addresses, routes and gateway. A machine with both talks IPv6 to whatever has an IPv6 address
and IPv4 to the rest. This office is built that way:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"The lab of this lesson, with both address families on every box. pc1 has 10.20.10.21 and 2001:db8:20:10:25:70ff:febc:29c6; pc2 has 10.20.10.22 and 2001:db8:20:10:fd:f2ff:fed2:63ba; srv has 10.20.10.10 and 2001:db8:20:10::10. The three are cabled to the switch sw1, and sw1 to the router r1, whose eth0 has 10.20.10.1 and 2001:db8:20:10::1 and whose eth1 has 203.0.113.2 and 2001:db8:ffff::2. r1 is cabled to the provider isp, and isp to the web server web, at 192.0.2.80 and 2001:db8:99::80. The networks: office LAN 10.20.10.0/24 and 2001:db8:20:10::/64; provider link 203.0.113.0/30 and 2001:db8:ffff::/64; web server 192.0.2.0/24 and 2001:db8:99::/64.\"><rect x=\"10\" y=\"20\" width=\"205\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:20:10:25:70ff:febc:29c6</text><path d=\"M215 49 L240 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"10\" y=\"90\" width=\"205\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.22</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:20:10:fd:f2ff:fed2:63ba</text><path d=\"M215 119 L240 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"10\" y=\"160\" width=\"205\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.10</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:20:10::10</text><path d=\"M215 189 L240 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"240\" y=\"106\" width=\"56\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><path d=\"M296 124 L318 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"318\" y=\"66\" width=\"158\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"330\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.10.1</text><text x=\"330\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 2001:db8:20:10::1</text><text x=\"330\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 203.0.113.2</text><text x=\"330\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 2001:db8:ffff::2</text><path d=\"M476 124 L500 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"106\" width=\"56\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><path d=\"M556 124 L576 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"576\" y=\"96\" width=\"134\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text><text x=\"588\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><text x=\"588\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:99::80</text><text x=\"10\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">office LAN</text><text x=\"10\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><text x=\"10\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2001:db8:20:10::/64</text><text x=\"318\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">provider link</text><text x=\"318\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.0/30</text><text x=\"318\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2001:db8:ffff::/64</text><text x=\"576\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">web server</text><text x=\"576\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.0/24</text><text x=\"576\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2001:db8:99::/64</text></svg>", "caption": "Every network in this lab has an IPv4 range and an IPv6 prefix, and every interface has an address from each. Link-local addresses are left out of the drawing."}
```

pc1's one interface, with everything it has:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if27        UP             10.20.10.21/24 2001:db8:20:10:25:70ff:febc:29c6/64 fe80::25:70ff:febc:29c6/64 
```

Three addresses on `eth0`. `10.20.10.21/24` is the IPv4 address lab.sh gave it, the one lesson 8
worked with. `2001:db8:20:10:25:70ff:febc:29c6/64` is the global IPv6 address it built by SLAAC, and
`fe80::25:70ff:febc:29c6/64` is its link-local address. **The two protocols do not share anything
above the cable**: IPv4 leaves through `10.20.10.1`, IPv6 through `fe80::1f:23ff:fee7:e9d5`, and a
problem in one says nothing about the other.

Which one does a program use? It asks for the name and gets a list:

```
ana@pc1:~$ getent ahosts web
2001:db8:99::80 STREAM web
2001:db8:99::80 DGRAM  
2001:db8:99::80 RAW    
192.0.2.80      STREAM 
192.0.2.80      DGRAM  
192.0.2.80      RAW    
```

`web` has two addresses, `2001:db8:99::80` and `192.0.2.80`, and **the IPv6 one comes first**.
(`STREAM`, `DGRAM` and `RAW` are the three kinds of socket each address could be used for; read only
the addresses.) In this lab the names come from each machine's `/etc/hosts`, which lab.sh wrote; on
the internet they come from DNS, where a name has an **A** record for IPv4 and an **AAAA** record for
IPv6, as the networks course showed. The order is the system's choice, and on a machine with a
global IPv6 address it puts IPv6 first. A program that tries the addresses in order therefore tries
IPv6 first.

`curl` can be told to use one protocol and not the other, which makes it the tool for testing each
path on its own:

```
ana@pc1:~$ curl -s -4 http://web/ -w "%{remote_ip}\n"
served by web
192.0.2.80
ana@pc1:~$ curl -s -6 http://web/ -w "%{remote_ip}\n"
served by web
2001:db8:99::80
```

Same server, same page, two different paths: `-4` connected to `192.0.2.80`, `-6` to
`2001:db8:99::80`, and `%{remote_ip}` printed the address each one actually reached.

That separate testing is the skill this section is for, because **the classic dual-stack failure is
an IPv6 path that is broken while IPv4 works**. The name has an AAAA record, the machine prefers
IPv6, the connection to the IPv6 address goes nowhere, and the user sees a site that is slow or
does not load, while every IPv4 test passes. Browsers soften it by trying both protocols almost at
once and keeping whichever answers first, a technique called Happy Eyeballs; command-line tools and
older programs do not, and they wait. **When a site fails from one machine, test `-4` and `-6`
separately before anything else.**

One more consequence, and it is a security one. A firewall written for IPv4 does nothing for IPv6
unless it was written for both: on Linux, `iptables` and `ip6tables` are separate programs, and an
nftables table of family `ip` sees only IPv4. In this lab, r1's only rule set is an IPv4 NAT table, so its IPv6 side forwards everything in both directions. That is acceptable in a lab with no
real internet and it is not acceptable anywhere else: **every rule a network has for IPv4 needs an
IPv6 counterpart**, written and tested on the same day.
