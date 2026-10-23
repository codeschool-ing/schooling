---
title: A blocklist the resolver reads
version: 1
---

**A response policy zone, RPZ, is a list of names and what the resolver should say about each one
instead of the truth.** It is written in the format of an ordinary DNS zone file, which is why it
can be shared between organisations and transferred like any other zone, and every major resolver
reads it: BIND, Unbound, PowerDNS, and the DNS services of most security vendors.

Each line names a trigger and an action. The two actions this lesson uses:

| written as | the resolver answers |
|---|---|
| `name CNAME .` | `NXDOMAIN`, "this name does not exist" |
| `name A 192.168.60.53` | the address given, whatever the real answer is |

A name can be exact, `boletos-jatoba.example.net`, or a whole family with a wildcard,
`*.cobranca-urgente.example.org`, which covers every name under that domain. The two entries below are
the firm's first decisions. The first is a lookalike domain sending fake payment slips to Jatobá's
clients; the second is a domain whose every subdomain is used to deliver files nobody should open.

```
root@dns:~# cat > /etc/unbound/feed.zone <<'EOF'
$TTL 300
@ SOA localhost. hostmaster.jatoba.example. 1 3600 600 86400 300
@ NS localhost.
boletos-jatoba.example.net      CNAME .
*.cobranca-urgente.example.org  A     192.168.60.53
EOF
root@dns:~# cat >> /etc/unbound/unbound.conf.d/jatoba.conf <<'EOF'
rpz:
    name: feed.jatoba.example
    zonefile: /etc/unbound/feed.zone
    rpz-log: yes
    rpz-log-name: feed
EOF
root@dns:~# unbound-checkconf && systemctl restart unbound; systemctl is-active unbound
unbound-checkconf: no errors in /etc/unbound/unbound.conf
active
```

The first three lines are what makes it a zone: a default lifetime of 300 seconds for every answer,
and the two records every zone has, its `SOA` and its `NS`. Their values matter to a zone that is
transferred between servers; to a file read from disk they only have to be there. The `rpz:` block
added to the resolver's configuration points at the file, gives it a name for the logs, and asks
Unbound to log every time it applies. This is the block `respip` in `module-config` was waiting for.

## What desk sees now

```
ana@desk:~$ dig boletos-jatoba.example.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 11682
ana@desk:~$ dig +short pagamento.cobranca-urgente.example.org
192.168.60.53
ana@desk:~$ dig +short web.jatoba.example
192.168.60.10
```

The lookalike does not exist, as far as `desk` can tell. The download domain answers with the
address of `dns` itself, which the next section puts to work. And the firm's own name is untouched:
a policy zone changes only the names it lists.

## What the resolver writes down

```
root@dns:~# journalctl -u unbound -o cat | grep "rpz: applied" | cut -d" " -f3-
rpz: applied [feed] boletos-jatoba.example.net. rpz-nxdomain 192.168.60.20@46963 boletos-jatoba.example.net. A IN
rpz: applied [feed] *.cobranca-urgente.example.org. rpz-local-data 192.168.60.20@54498 pagamento.cobranca-urgente.example.org. A IN
```

Each line says which zone matched, which entry matched (the wildcard shows as written), what was
done, and who asked: `192.168.60.20` is `desk`, and the number after the `@` is the port its
question came from. **A blocked lookup is a finding, not only a prevention.** Somebody on `desk`
followed a link to a domain the firm has listed as dangerous, and the person who reads this log knows
it within a minute, without anybody on `desk` having reported anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l14-rpz\" aria-label=\"Three questions from desk reach dns and leave with three different answers. web.jatoba.example is not on the list and gets its real address, 192.168.60.10. boletos-jatoba.example.net matches an entry written CNAME dot and gets NXDOMAIN. pagamento.cobranca-urgente.example.org matches a wildcard entry with an address and gets 192.168.60.53, the sinkhole.\"><defs><marker id=\"l14-rpz-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-rpz-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-rpz-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"290.0\" y=\"90.0\" width=\"140.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dns</text><text x=\"360.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads feed.zone</text><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web.jatoba.example</text><path d=\"M220.0 50.0 L290.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-paper-dim)\"></path><path d=\"M430.0 125.0 L520.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-phosphor)\"></path><text x=\"530.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not listed</text><text x=\"530.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">192.168.60.10</text><text x=\"20.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">boletos-jatoba.example.net</text><path d=\"M220.0 110.0 L290.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-paper-dim)\"></path><path d=\"M430.0 125.0 L520.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-amber)\"></path><text x=\"530.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME .</text><text x=\"530.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">NXDOMAIN</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pagamento.cobranca-urgente…</text><path d=\"M220.0 170.0 L290.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-paper-dim)\"></path><path d=\"M430.0 125.0 L520.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-amber)\"></path><text x=\"530.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">A 192.168.60.53</text><text x=\"530.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">192.168.60.53</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the question is the same; the list decides the answer</text></svg>", "caption": "A policy zone changes only the names it lists, and says why each time."}
```

Why `NXDOMAIN` for one and an address for the other? `NXDOMAIN` is the quiet refusal: the program
gets nothing and gives up, and nothing more is learnt. An address sends the program somewhere you
choose, and that somewhere can record what it was trying to do. The next section builds it.
