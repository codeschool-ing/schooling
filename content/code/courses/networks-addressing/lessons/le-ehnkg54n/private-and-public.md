---
title: Private inside, public outside
version: 1
---

A common belief is that every computer on the internet has an address of its own that the rest of
the internet can see. pc1's address is `10.20.10.21`, and no machine outside this office will ever
see it in a packet. Thousands of other offices use exactly the same address for one of their own
machines at this moment, and none of them conflicts with pc1.

That works because of three blocks that RFC 1918 (1996) set aside for **private** use:

| block | range | size |
|---|---|---|
| `10.0.0.0/8` | 10.0.0.0 to 10.255.255.255 | 16,777,216 addresses |
| `172.16.0.0/12` | 172.16.0.0 to 172.31.255.255 | 1,048,576 addresses |
| `192.168.0.0/16` | 192.168.0.0 to 192.168.255.255 | 65,536 addresses |

Anybody may use them without asking anybody, and **no provider routes them across the internet**: a
packet addressed to 10.20.10.21 from outside has nowhere to go. A private address is unique only
inside its own network, which is all an office needs for its own machines. The middle block is the
one people misremember: it is `172.16` to `172.31`, so `172.32.0.1` is an ordinary public address.

pc1 and the router, side by side:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if430       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if438       UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth1@if440       UP             203.0.113.2/30 fe80::a6:80ff:fe20:1354/64 
```

pc1 has one address, private. r1 has one on each side: `10.20.10.1/24` on `eth0`, the office's
gateway, and `203.0.113.2/30` on `eth1`, facing the provider. (The `fe80::` addresses beside them
are IPv6, which lesson 9 explains; `lo` is the next section.) The router is where the private world
ends:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"The office of this lesson's lab. On the inside, with private addresses in 10.20.10.0/24: pc1 at 10.20.10.21, pc2 at 10.20.10.22, pc3 at 10.20.10.23 and srv at 10.20.10.10, all cabled to the switch sw1, which is cabled to the router r1, whose eth0 is 10.20.10.1. r1's eth1, 203.0.113.2, is on the outside, cabled to the provider isp at 203.0.113.1. Every office packet leaves from 203.0.113.2, which lesson 11 explains.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inside: private addresses, 10.20.10.0/24</text><text x=\"500\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">outside: public addresses</text><path d=\"M480 6 L480 256\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"20\" y=\"34\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.21</text><path d=\"M150 56 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"90\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"32\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.22</text><path d=\"M150 112 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"146\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"32\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.23</text><path d=\"M150 168 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"202\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"32\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.10</text><path d=\"M150 224 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"210\" y=\"122\" width=\"70\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><path d=\"M280 140 L320 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"320\" y=\"104\" width=\"140\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"332\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"332\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth0 10.20.10.1</text><text x=\"332\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">eth1 203.0.113.2</text><path d=\"M460 158 L570 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"570\" y=\"122\" width=\"130\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"582\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><text x=\"582\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.1</text><text x=\"500\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every office packet leaves</text><text x=\"500\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">from 203.0.113.2 (lesson 11)</text></svg>", "caption": "Four private addresses inside and one public address on the router's outside interface. The dashed line is the edge of the office network."}
```

**Every packet the office sends to the internet leaves with r1's public address as its source.** The
router rewrites the private source on the way out and puts it back on the answers, which is NAT, the
subject of lesson 11. To the rest of the internet, the whole office is one address.

Now ask ipcalc about the two addresses that are not private:

```
ana@pc1:~$ ipcalc -b 203.0.113.2
Address:   203.0.113.2          
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   203.0.113.0/24       
HostMin:   203.0.113.1          
HostMax:   203.0.113.254        
Broadcast: 203.0.113.255        
Hosts/Net: 254                   Class C

ana@pc1:~$ ipcalc -b 100.64.1.1
Address:   100.64.1.1           
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   100.64.1.0/24        
HostMin:   100.64.1.1           
HostMax:   100.64.1.254         
Broadcast: 100.64.1.255         
Hosts/Net: 254                   Class A

```

`203.0.113.2` gets `Class C` and nothing else, as a public address would. It is not an ordinary
public address, though. **`203.0.113.0/24` is one of three blocks that RFC 5737 reserves for
documentation**, with `192.0.2.0/24` and `198.51.100.0/24`, so that a book, a manual or a lab can
print an address that belongs to nobody. This lab uses them to play the public internet, which is
why its transcripts are safe to publish. This ipcalc does not know those blocks, and does not say
so.

`100.64.1.1` gets `Class A` and nothing else, and that is also incomplete. **`100.64.0.0/10` is
shared address space (RFC 6598, 2012)**: addresses a provider uses between its customers' routers
and its own NAT, when it has too few public addresses to give each customer one. That arrangement is
called carrier-grade NAT, and lesson 11 comes back to it. If the outside interface of a home router
shows an address from `100.64.0.1` to `100.127.255.254`, the customer is behind a second NAT run by
the provider, and nobody on the internet can open a connection to that home directly.

Two things to keep from this output. A calculator knows the ranges its author taught it, and this
one stopped at RFC 1918. **Whether an address is private, documentation or shared is a fact you can
check against the table yourself**, and this lesson's last section has the full table.
