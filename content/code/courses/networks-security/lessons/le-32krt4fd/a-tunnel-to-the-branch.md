---
title: Both halves at work, in a tunnel to the branch
version: 1
---

The branch office sits on the internet segment behind its own router, `branch`, and its staff need
the application on `app`. Opening `app` to the internet is out of the question after lesson 4. A **site-to-site
VPN** joins the two networks through an encrypted tunnel instead: packets between the branch and the
head office travel inside it, and the internet in between sees only the tunnel.

**WireGuard** is the whole of this lesson in one protocol. Each end has a Curve25519 key pair:

```
root@fw:~# umask 077; wg genkey > wg.key; wg pubkey < wg.key > wg.pub; cat wg.pub
KZle1OHbaXxpMFIftlwMzvHqanoqRZ9xDlvDtzi6Oy8=
root@branch:~# umask 077; wg genkey > wg.key; wg pubkey < wg.key > wg.pub; cat wg.pub
RzVWXllEFMVGdig288pqtFqTXs//oftHmzj6v9yYtlU=
```

The configuration on `fw` names its own private key, and for its one peer, the branch: its public key,
where to find it, and which addresses may come through the tunnel from it:

```
root@fw:~# sed "s/^PrivateKey = .*/PrivateKey = (the contents of wg.key)/" wg0.conf
[Interface]
ListenPort = 51820
PrivateKey = (the contents of wg.key)

[Peer]
# the branch office
PublicKey = RzVWXllEFMVGdig288pqtFqTXs//oftHmzj6v9yYtlU=
Endpoint = 203.0.113.70:51820
AllowedIPs = 10.99.0.2/32, 192.168.30.0/24
```

`AllowedIPs` is both a routing table and a filter: packets arriving through the tunnel from this peer
must come from those addresses, or they are dropped. The interface is brought up on each end, with a
route to the other side's network through it, and `fw` gets two rules, one letting the tunnel's UDP in
and one letting the branch use the application:

```
root@fw:~# wireguard-go wg0 2>/dev/null && wg setconf wg0 wg0.conf && ip addr add 10.99.0.1/24 dev wg0 && ip link set wg0 up && ip route add 192.168.30.0/24 dev wg0
root@branch:~# wireguard-go wg0 2>/dev/null && wg setconf wg0 wg0.conf && ip addr add 10.99.0.2/24 dev wg0 && ip link set wg0 up && ip route add 192.168.10.0/24 dev wg0 && ip route add 192.168.20.0/24 dev wg0
root@fw:~# nft list ruleset | grep -E "branch"
		iifname "wg0" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the branch uses the application"
		iifname "eth0" udp dport 51820 accept comment "the branch tunnel"
```

Then a computer in the branch asks for the application's health page, and `fw` shows the tunnel:

```
ana@branchpc:~$ curl -s -m5 http://192.168.20.10:8080/health
status: ok
root@fw:~# wg show wg0 | grep -vE "public key|private key"
interface: wg0
  listening port: 51820

peer: RzVWXllEFMVGdig288pqtFqTXs//oftHmzj6v9yYtlU=
  endpoint: 203.0.113.70:51820
  allowed ips: 10.99.0.2/32, 192.168.30.0/24
  latest handshake: 2 seconds ago
  transfer: 1.10 KiB received, 860 B sent
```

**A handshake two seconds ago**, and traffic both ways. What the internet segment carried meanwhile,
recorded on `fw`'s outside interface:

```
root@fw:~# cut -d" " -f2- wire.txt
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 148
IP 203.0.113.2.51820 > 203.0.113.70.51820: UDP, length 92
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 32
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 96
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 96
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 96
```

Only UDP between the two routers on port 51820. The first two packets, **148 and 92 bytes, are the
handshake**: the asymmetric half, where the two ends combine their key pairs into fresh symmetric keys.
Everything after is the symmetric half, ChaCha20-Poly1305: the 32-byte packet is an empty keepalive, and
the rest carry the branch's request and its answer. Somebody on the path learns that the two offices
talk, how often and how much, and nothing of what was said.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A site-to-site tunnel. branchpc, in the branch office, sends a request to app. The branch router, branch, puts it inside a WireGuard packet addressed to fw, UDP port 51820, across the internet segment. fw takes it out of the tunnel and passes it through its forward chain to app on port 8080. On the internet segment only the outer UDP packets between 203.0.113.70 and 203.0.113.2 are visible.\"><defs><marker id=\"vp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">branchpc</text><text x=\"30\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.30.20</text><rect x=\"170\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">branch</text><text x=\"180\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">wg0</text><rect x=\"430\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"440\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">wg0</text><rect x=\"580\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"590\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:8080</text><path d=\"M140 83 L170 83\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vp-ah-paper-dim)\"></path><path d=\"M550 83 L580 83\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vp-ah-paper-dim)\"></path><rect x=\"290\" y=\"70\" width=\"140\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">UDP 51820</text><rect x=\"160\" y=\"20\" width=\"400\" height=\"110\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"168\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">internet</text><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">encrypted: ChaCha20-Poly1305</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inside the tunnel: GET /health from 192.168.30.20 to 192.168.20.10</text><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the internet segment: UDP between 203.0.113.70 and 203.0.113.2, sizes and times</text></svg>", "caption": "The request travels inside the tunnel; the internet sees two routers exchanging UDP."}
```

**The tunnel does not replace the firewall.** Packets leaving `wg0` still cross `fw`'s forward chain,
and the rule written for them allows the branch exactly what it needs, the application on 8080. A VPN
decides who can join the network; the matrix of lesson 4 still decides what they may reach once they
have.
