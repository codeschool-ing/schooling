---
title: Ticket: "the server comes and goes"
version: 1
---

A new printer was installed this morning, and since then the office server is unreachable at times.
The printer was given an address by hand, and it is the server's:

```
ana@laptop:~$ sudo ip neigh flush dev eth0; ping -c 1 192.168.10.10 >/dev/null; ip neigh show 192.168.10.10
192.168.10.10 dev eth0 lladdr 52:54:00:99:00:01 REACHABLE 
ana@laptop:~$ sudo timeout 4 tcpdump -i eth0 -n -e -l arp 2>/dev/null
16:00:38.092218 52:54:00:a8:0a:14 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.10 tell 192.168.10.20, length 28
16:00:38.092262 52:54:00:99:00:01 > 52:54:00:a8:0a:14, ethertype ARP (0x0806), length 42: Reply 192.168.10.10 is-at 52:54:00:99:00:01, length 28
16:00:38.092264 52:54:00:a8:0a:0a > 52:54:00:a8:0a:14, ethertype ARP (0x0806), length 42: Reply 192.168.10.10 is-at 52:54:00:a8:0a:0a, length 28

ana@laptop:~$ nc -zv -w 3 192.168.10.10 22
nc: connect to 192.168.10.10 port 22 (tcp) failed: Connection refused
```

The laptop forgot its neighbours and pinged `192.168.10.10`, and the table then held `52:54:00:99:00:01`,
a MAC address the server does not have. tcpdump shows why: one ARP request, `who-has 192.168.10.10`,
and **two replies**, from two different machines. The printer's arrived first, and the laptop believed
it. So the next connection meant for the server went to the printer, which has nothing on port 22 and
refused it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A duplicate address. The laptop broadcasts an ARP request: who has 192.168.10.10? Two machines answer. The printer, just plugged in, answers first, with 52:54:00:99:00:01; the server answers with 52:54:00:a8:0a:0a. The laptop kept the printer&#x27;s answer, so its connections meant for the server went to the printer, which refused them.\"><defs><marker id=\"dp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"32\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"560\" y=\"20\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">printer, just plugged in</text><text x=\"572\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><rect x=\"560\" y=\"150\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><text x=\"572\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><path d=\"M140 108 L558 48\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\" stroke-dasharray=\"4 4\"></path><path d=\"M140 118 L558 172\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\" stroke-dasharray=\"4 4\"></path><text x=\"150\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">who has 192.168.10.10?</text><path d=\"M558 62 L142 124\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><text x=\"360\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">is-at 52:54:00:99:00:01</text><path d=\"M558 186 L142 132\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><text x=\"300\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">is-at 52:54:00:a8:0a:0a</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the laptop kept the printer’s answer</text></svg>", "caption": "Two devices with one address both answer ARP, and each client believes whichever it heard. Which one it is can change from minute to minute, which is why a duplicate address looks like a fault that comes and goes."}
```

A different moment, or a different PC, can hear the server first, which is why the complaint is that
things come and go. **Two replies to one ARP request is the proof**. The MAC in the wrong reply leads to
the device: the switch's table says which port it is on, and the first half of a MAC names the maker.
The fix is an address outside the range DHCP hands out, or a reservation in DHCP, so that no address is
ever given twice.
