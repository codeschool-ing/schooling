---
title: A stateless filter, and the rule it forces you to write
version: 1
---

**A stateless filter judges every packet on its own.** It remembers nothing: a packet is let
through or dropped by what its own headers say, and the packet before it makes no difference. The
filters in most routers work like this, and lesson 17 writes them in that syntax.

The staff on the LAN need the application on `app`, port 8080, and nothing else on the servers
segment. Written as a stateless rule set in nftables, on `fw`:

```
root@fw:~# cat stateless.nft
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    iifname "eth2" oifname "eth3" tcp dport 8080 accept
  }
}
root@fw:~# nft -f stateless.nft
```

Read from the top. A **table** holds chains; `ip` says it handles IPv4. The **chain** hooks into
`forward`, so it sees traffic crossing `fw`, and `policy drop` is its verdict for any packet no rule
accepted. The one rule accepts what arrives from the LAN (`eth2`) and leaves towards the servers
(`eth3`) for port 8080.

Then `laptop` asks for the application's health page:

```
ana@laptop:~$ curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"
exit 28
```

Exit 28 is `curl` giving up after its three seconds. The request did reach `app`. **The answer did
not come back**, because the answer is a packet too, travelling from `app` to `laptop`, and nothing
accepts that. A filter that remembers nothing has no idea the reply belongs to a request it let
through.

So a stateless rule set needs a second rule for every conversation it allows, written for the other
direction:

```
root@fw:~# nft -f stateless.nft
ana@laptop:~$ curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"
status: ok
exit 0
```

It works. It also opens a door that nobody meant to open, and the next section walks through it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three machines: laptop on the left, fw in the middle, and on the right app and db. Rule 1 lets laptop&#x27;s request through to app on destination port 8080. Rule 2 lets app&#x27;s reply back because its source port is 8080. A dashed line shows db opening a connection to laptop with source port 8080 as well, and rule 2 lets it through too, because a stateless rule sees only the number on the packet.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"300\" y=\"90\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"310\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no memory</text><rect x=\"570\" y=\"40\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"580\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.10</text><rect x=\"570\" y=\"164\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"580\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M150 100 L300 100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M420 100 L570 66\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"160\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">rule 1: dport 8080</text><path d=\"M570 76 L420 116\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M300 116 L150 116\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"160\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rule 2: sport 8080, the reply</text><path d=\"M570 186 L360 186 L360 136\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-amber)\" stroke-dasharray=\"4 3\"></path><path d=\"M330 136 L330 170\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><path d=\"M330 170 L85 170 L85 136\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"430\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">db, source port 8080: also rule 2</text></svg>", "caption": "Rule 2 was written for replies. It matches anything with the same number."}
```
