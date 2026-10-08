---
title: Both at once
version: 2
---

In client-server the roles are fixed for the whole service: browsers are clients, the web server is a
server. **In peer to peer, every machine runs both roles**: it listens for others and connects to
others, and no single machine holds the service. A file shared over BitTorrent is the instance most
people have met: each computer downloading it also serves the pieces it already has to the others.

The lab shows the shape with two PCs. Each one starts a listener on port 8000,
`timeout 8 nc -l 8000`, and then each one connects to the other's, `sleep 5 | timeout 6 nc pc2 8000`
on pc1 and the same towards pc1 on pc2. Both list their TCP connections with `ss -tn`:

```
ana@pc1:~$ ss -tn
State Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
ESTAB 0      0        10.20.10.21:8000   10.20.10.22:40206       
ESTAB 0      0        10.20.10.21:35592  10.20.10.22:8000        
ana@pc2:~$ ss -tn
State Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
ESTAB 0      0        10.20.10.22:8000   10.20.10.21:35592       
ESTAB 0      0        10.20.10.22:40206  10.20.10.21:8000        
```

pc1 has two connections, and they have different roles. In the first, pc1's side is
`10.20.10.21:8000`, its listening port: pc2 connected to it from port `40206`, so in this
conversation pc1 is the server and pc2 the client. In the second, pc1's side is the ephemeral port
`35592` and the far side is `10.20.10.22:8000`: pc1 connected out, and here it is the client.

pc2's listing is the same two connections seen from the other end. `10.20.10.22:8000` with peer
`10.20.10.21:35592` is pc1's second line with the sides swapped, and `10.20.10.22:40206` with peer
`10.20.10.21:8000` is pc1's first. **The role belongs to each connection, not to the machine**: pc1 is
a server and a client in the same second, and nothing about the computer changed between the two
lines.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 186\" role=\"img\" aria-label=\"Two peers from the office lab, pc1 at 10.20.10.21 and pc2 at 10.20.10.22. Each listens on port 8000. Connection 1 goes from pc1's ephemeral port 35592 to pc2's port 8000; connection 2 goes from pc2's ephemeral port 40206 to pc1's port 8000. Each machine is the server of one connection and the client of the other.\"><defs><marker id=\"peer-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"240\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"80\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><rect x=\"34\" y=\"56\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">:35592</text><text x=\"116\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client side</text><rect x=\"34\" y=\"108\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:8000</text><text x=\"116\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">listening</text><rect x=\"460\" y=\"20\" width=\"240\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"474\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"520\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.22</text><rect x=\"474\" y=\"56\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"486\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:8000</text><text x=\"556\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">listening</text><rect x=\"474\" y=\"108\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"486\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">:40206</text><text x=\"556\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client side</text><path d=\"M234 74 L470 74\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#peer-ah)\"></path><text x=\"352\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">connection 1: pc1 asks</text><path d=\"M474 126 L238 126\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#peer-ah)\"></path><text x=\"352\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">connection 2: pc2 asks</text></svg>", "caption": "The two connections both listings show. Each peer is a server in one and a client in the other."}
```

What peer to peer gains is that no one machine is required. If pc2 disappears, pc1 still has its
listener and can talk to anybody else running the program, and the more peers there are, the more
machines are serving. What it has to solve instead is **discovery**. pc1 found pc2 because the lab
wrote pc2's address into pc1's `/etc/hosts`; among strangers on the internet there is no such file.
Real P2P systems find their peers in one of three ways:

- through a server that keeps a list of who has what, which is what a BitTorrent tracker is;
- through the peers themselves, in a distributed hash table (DHT), where each peer knows a few others
  and asks them in turn;
- through both, trying the tracker and the DHT together.

In other words, most of them keep a little client-server for the part that is hard to share.
