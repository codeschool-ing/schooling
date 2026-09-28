---
title: What a firewall decides, and where
version: 1
---

A firewall is not a wall. It is a **list of questions asked about each packet as it crosses a
machine**, and a verdict for each answer: let it through, or drop it. Everything this course builds
on the network side comes down to writing those questions well.

This course has one lab, and every lesson starts it fresh. It is a small company: a firewall called
`fw` with five network interfaces, and behind each one a segment that should be trusted differently.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 410\" role=\"img\" aria-label=\"The course&#x27;s lab. In the middle, the firewall fw. Above it, the internet segment, 203.0.113.0/24, with remote, a stranger, and branch, the branch office&#x27;s router. To the left, the staff LAN, 192.168.10.0/24, with laptop and desk. To the right, the DMZ, 192.0.2.0/24, with www and dns. Below, the servers segment, 192.168.20.0/24, with app and db, and the management segment, 192.168.99.0/24, with admin. Each segment reaches the others only through fw.\"><defs><marker id=\"lm-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M360 180 L360 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M290 203 L206 203\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M430 203 L514 203\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M330 226 L230 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M390 226 L490 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><text x=\"366\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth0</text><text x=\"248\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth2</text><text x=\"472\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth1</text><text x=\"262\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth3</text><text x=\"458\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth4</text><rect x=\"200\" y=\"10\" width=\"320\" height=\"86\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"208\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">internet</text><text x=\"510\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.0/24</text><rect x=\"215\" y=\"36\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote</text><text x=\"225\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a stranger</text><rect x=\"360\" y=\"36\" width=\"145\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">branch</text><text x=\"370\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the branch office</text><rect x=\"290\" y=\"180\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"300\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">routes and filters</text><rect x=\"10\" y=\"130\" width=\"196\" height=\"146\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"18\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">staff LAN</text><text x=\"198\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.0/24</text><rect x=\"24\" y=\"158\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"34\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"24\" y=\"214\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">desk</text><text x=\"34\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.21</text><rect x=\"514\" y=\"130\" width=\"196\" height=\"146\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"522\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">DMZ</text><text x=\"702\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.0/24</text><rect x=\"528\" y=\"158\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"538\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.80</text><rect x=\"528\" y=\"214\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dns</text><text x=\"538\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.53</text><rect x=\"40\" y=\"300\" width=\"330\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"48\" y=\"312\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">servers</text><text x=\"362\" y=\"312\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.0/24</text><rect x=\"54\" y=\"330\" width=\"148\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"64\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"64\" y=\"363\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.10</text><rect x=\"212\" y=\"330\" width=\"148\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"222\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"222\" y=\"363\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.30</text><rect x=\"420\" y=\"300\" width=\"220\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"428\" y=\"312\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">management</text><text x=\"632\" y=\"312\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.99.0/24</text><rect x=\"434\" y=\"330\" width=\"192\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"444\" y=\"363\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.99.10</text></svg>", "caption": "One firewall, five segments. Every lesson starts from this map."}
```

`lab.sh`, beside the course, builds it out of network namespaces on one Linux computer. Each
namespace has its own interfaces, routes and firewall, so each behaves as a machine of its own. The
addresses come from the ranges reserved for documentation, and nothing in the lab reaches the real
internet.

**When the lab comes up, `fw` routes everything and filters nothing.** That is the state of more
networks than anybody admits, and it is worth seeing once. `remote` is a stranger on the internet
segment; `db` holds the company's database and `app` its internal application:

```
ana@remote:~$ nc -w2 192.168.20.30 5432 </dev/null
db ready
ana@remote:~$ curl -s -m2 http://192.168.20.10:8080/admin/
admin console
```

A stranger opened a connection to the database port and read the application's admin page. Nothing
was broken to do it. The router did its job, which is to deliver packets, and **nothing on the path
was asked whether it should**.

## Three places a packet can meet the rules

Linux runs a packet past its rules at fixed points, called **hooks**. Three matter for filtering:

| hook | the packet is | example on `fw` |
|---|---|---|
| `input` | addressed to this machine | somebody opening SSH to `fw` itself |
| `forward` | crossing this machine to another | `laptop` reaching `app` through `fw` |
| `output` | leaving this machine, made here | `fw` asking DNS for a name |

A firewall that protects the machines **behind** it writes its rules in `forward`. A host firewall,
which protects only the machine it runs on, writes them in `input`. Lesson 21 puts one on every
server; until then, almost every rule here is in `forward`.

## What a rule can look at

Each packet carries the same few facts in its headers, and a rule may test any of them:

- the **interface** it arrived on and the one it will leave by: `iifname "eth2"`, `oifname "eth3"`;
- the **source and destination address**: `ip saddr`, `ip daddr`;
- the **protocol**, and for TCP and UDP the **source and destination port**: `tcp dport 8080`.

The addresses, the protocol and the two ports are the **five-tuple**, and they name one
conversation. Interfaces matter as much as addresses. An address is written by whoever sent the
packet, and lesson 8 shows why that cannot be trusted on its own; the interface is where the cable
actually is.

The tool on `fw` is **nftables**, the `nft` command. `iptables` is its predecessor, and on current
distributions it is a compatibility layer that writes nftables rules underneath. On `fw` it says so
itself:

```
root@fw:~# iptables -V
iptables v1.8.10 (nf_tables)
```

The ideas in this course are the same in both, and in the firewall appliances lesson 2 turns to.
