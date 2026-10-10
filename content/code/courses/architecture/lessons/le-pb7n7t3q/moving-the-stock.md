---
title: Moving the stock, a tenth at a time
version: 1
---

The new stock service is running, and nobody is using it. The first real traffic it gets should be a
small share, so that a mistake hurts few people: a **canary**, after the birds miners carried to find
bad air before it reached them. Send ten per cent of `/stock/` to it by rewriting the split file and
reloading the edge:

```sh
cat > stock-split.conf <<'EOF'
split_clients "${request_id}" $stock_backend {
    10% stock;
    * monolith;
}
EOF
docker compose exec edge nginx -s reload
```

Then ask for the stock forty times and count who answered:

```
ana@vm:~/lab/strangler$ for i in $(seq 40); do curl -s localhost:8080/stock/coffee; done | sort | uniq -c
     35 monolith: coffee 12
      5 stock service: coffee 12
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The edge receives forty requests for /stock/coffee. A split sends ninety per cent to the monolith and ten per cent to the new stock service; in the lab&#x27;s run that was thirty-five and five. Changing the file and reloading the edge moves the share, up to all of it, or back to none.\"><defs><marker id=\"l15-split-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-split-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-split-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">40 requests</text><rect x=\"250\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">edge</text><path d=\"M172 105 L248 105\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-split-ah-wire)\"></path><rect x=\"500\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">monolith: 35</text><rect x=\"500\" y=\"130\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">stock service: 5</text><path d=\"M392 95 L498 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-split-ah-paper-dim)\"></path><path d=\"M392 115 L498 155\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-split-ah-amber)\"></path><text x=\"430\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90%</text><text x=\"430\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">10%</text></svg>", "caption": "A canary: the new service gets a small share of real traffic first, and the share grows only while it behaves."}
```

Five of forty went to the new service, close to the ten per cent asked for; each request is assigned on
its own, so a short run lands near the share rather than on it. The answers are the same number, which
is the first check a canary is for: **the new service agrees with the old one**. In a real migration the
check is broader, comparing error rates and latency of the two backends side by side, and a dashboard
that shows them is worth building before the first per cent moves.

Write the file with `cat >`, as above, rather than with an editor that saves to a new file and renames
it: the edge's container sees the file through a mount, and a rename leaves it looking at the old one.

When the share has grown without trouble, send everything:

```sh
cat > stock-split.conf <<'EOF'
split_clients "${request_id}" $stock_backend {
    * stock;
}
EOF
docker compose exec edge nginx -s reload
```

```
ana@vm:~/lab/strangler$ for i in $(seq 40); do curl -s localhost:8080/stock/coffee; done | sort | uniq -c
     40 stock service: coffee 12
```

**The way back is the same two commands** with the old split. That is what makes the strangler safe: a
wrong step costs the time it takes to edit a file, not a restore from backup. Only when the new service
has carried all the traffic for long enough that nobody would roll back does the monolith's stock code
get deleted, and with it the last way back.
