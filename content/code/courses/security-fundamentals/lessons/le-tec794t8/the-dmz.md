---
title: The DMZ
version: 1
---

The shop has one server the whole internet is meant to reach: `www`, which serves the shop's pages
and the staff portal. It also has a database, `db`, that nobody on the internet should ever reach,
and an office with staff laptops.

Putting the public server inside with everything else would mean opening a path from the internet
into the trusted network, and a server everybody can talk to is the server most likely to be
compromised. Putting it outside the firewall would leave it unprotected. **The answer is a third
zone: the DMZ.**

The name is borrowed from the demilitarised zone between two countries, a strip that belongs to
neither side. In a network, the **DMZ** is a segment for the services the outside must reach, with
a firewall between it and the internet and another boundary between it and the inside. Its rules
say three things:

1. **the internet may reach the DMZ**, but only the services that are meant to be public;
2. **the DMZ may reach the inside** only where a public service needs something specific, and only
   that;
3. **the internet may never reach the inside directly.**

Here is the lab drawn as zones, which is how the shop's network looks in this lesson:

```schooling-figure
{"svg": "<svg id=\"sf-zones\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The course's lab drawn as zones. The firewall fw sits in the middle with four legs: eth0 to the internet, where outside is; eth1 to the DMZ, where www is; eth2 to the office, where laptop is; eth3 to the servers, where db is. Three allowed paths are listed: 1, the internet to www on port 80; 2, www to db on port 5432; 3, the office to the internet and to www. Everything else is dropped.\"><rect x=\"20\" y=\"20\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">internet · 203.0.113.0/24</text><rect x=\"70\" y=\"56\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">outside</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">DMZ · 192.0.2.0/24</text><rect x=\"530\" y=\"56\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><rect x=\"20\" y=\"190\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">office · 192.168.10.0/24</text><rect x=\"70\" y=\"226\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><rect x=\"480\" y=\"190\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">servers · 192.168.20.0/24</text><rect x=\"530\" y=\"226\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><rect x=\"300\" y=\"130\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">fw</text><path d=\"M240 70 L300 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M480 70 L420 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M240 240 L300 160\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M480 240 L420 160\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><text x=\"262\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth0</text><text x=\"458\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth1</text><text x=\"262\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth2</text><text x=\"458\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth3</text><text x=\"360\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1 internet → www:80</text><text x=\"360\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">2 www → db:5432</text><text x=\"360\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">3 office → internet, www</text><text x=\"360\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">everything else: dropped</text></svg>", "caption": "The shop's zones, and the three paths this lesson's rules allow. Anything not listed is dropped by default."}
```

The DMZ's value comes from the second rule. If `www` is compromised, the attacker is in the DMZ,
not inside, and from there the firewall allows exactly one thing: a connection to the database's
port. Not the office, not the database's other services, not the internet in some other way. The
damage a compromised public server can do is limited to what it was allowed to do anyway.

Some networks build the DMZ with one firewall that has three legs, as the lab does; others put two
firewalls in a row, an outer one between the internet and the DMZ and an inner one between the DMZ
and the inside. The second shape costs more and, in the language of lesson 4, it is two layers
rather than one, especially if the two firewalls come from different vendors.
`networks-security` lesson 4 builds both.

**What goes in a DMZ:** anything that must answer the internet. Web servers, the mail server that
receives email, the public DNS server, a VPN gateway. **What never goes in a DMZ:** the data those
services use. The shop's orders live in `db`, inside; the web server in the DMZ asks for them
through one allowed port, and never holds a copy.
