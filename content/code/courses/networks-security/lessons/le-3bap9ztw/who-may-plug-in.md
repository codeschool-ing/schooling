---
title: Who may plug in
version: 1
---

Every control in this course so far has trusted one thing without saying so: that whatever is plugged
into the office LAN belongs there. Lesson 7 showed what a machine on the segment can do to its
neighbours, and lesson 21 walled the servers off from each other. Neither asks the question underneath:
**who decided this machine could join the network at all?**

On most office networks, nobody did. A wall socket in a meeting room is a live port on a switch, and a
laptop plugged into it gets an address, a route and the whole LAN, whoever owns it. **Network access
control (NAC)** is the name for making that a decision, and **IEEE 802.1X** is the standard way to
make it on a switch port or a Wi-Fi network.

802.1X names three parties:

| party | in this lesson | its job |
|---|---|---|
| **supplicant** | `newpc` and `visitor` | the machine asking to join, and the software on it that proves who it is |
| **authenticator** | `sw`, the access switch | keeps the port closed, relays the exchange, and opens the port when told to |
| **authentication server** | hostapd's own EAP server, inside `sw` | checks the credentials and says yes or no; in a real network this is a **RADIUS** server |

The authenticator never judges the credentials itself. It carries **EAP** messages between the other
two, wrapped in **EAPOL** frames (EAP over LAN) on the cable and in RADIUS towards the server. That split
is what lets one policy server decide for hundreds of switches and access points.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"802.1X on the lab&#x27;s access switch. newpc, on port p1, is the supplicant and talks EAPOL to the switch, the authenticator. The switch passes the exchange to the authentication server, RADIUS in a real network, and opens p1 to the office LAN only after success. visitor, on port p2, offers a certificate it signed itself; the server refuses it and p2 stays closed to everything except EAPOL.\"><defs><marker id=\"dx-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dx-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dx-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">newpc</text><text x=\"30\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">supplicant</text><rect x=\"20\" y=\"150\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">visitor</text><text x=\"30\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own certificate</text><rect x=\"280\" y=\"30\" width=\"170\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw</text><text x=\"290\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">authenticator</text><rect x=\"280\" y=\"72\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">p1</text><rect x=\"280\" y=\"160\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p2</text><path d=\"M170 72 L280 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-phosphor)\" marker-start=\"url(#dx-ah-phosphor)\"></path><text x=\"225\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">EAPOL</text><path d=\"M170 176 L280 173\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-amber)\" marker-start=\"url(#dx-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"225\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">EAP server</text><text x=\"550\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RADIUS in a real network</text><path d=\"M450 55 L540 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-paper-dim)\" marker-start=\"url(#dx-ah-paper-dim)\"></path><text x=\"495\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RADIUS</text><rect x=\"540\" y=\"140\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">192.168.10.0/24</text><text x=\"550\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">office LAN</text><path d=\"M450 160 L540 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-phosphor)\"></path><text x=\"495\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">after success</text></svg>", "caption": "Three parties, and a port that stays shut until the third one says yes."}
```

The lab adds an access switch, `sw`, to the office LAN. Its port `p1` has a company laptop, `newpc`, and
`p2` has `visitor`, somebody's own machine. Before anything authenticates, the switch's filter is this:

```
root@sw:~# nft list table netdev ports
table netdev ports {
	set authorised {
		type ifname . ether_addr
	}

	chain p1 {
		type filter hook ingress device "p1" priority filter; policy drop;
		ether type 0x888e accept
		iifname . ether saddr @authorised accept
	}

	chain p2 {
		type filter hook ingress device "p2" priority filter; policy drop;
		ether type 0x888e accept
		iifname . ether saddr @authorised accept
	}
}
```

Each port's ingress chain drops by default. The one thing it accepts is EtherType `0x888e`, which is
EAPOL, because the machine needs some way to ask. Everything else waits for its port and address to
appear in the set `authorised`, which is empty.

So `newpc` has an address and a cable, and nowhere to go:

```
ana@newpc:~$ ip -br address show eth0
eth0@if1856      UP             192.168.10.30/24 
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1025ms
```

**The address is not the access.** It configured `192.168.10.30` on its own interface, but not one
frame other than EAPOL reaches the LAN yet, ARP included.
