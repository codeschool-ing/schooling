---
title: DNSSEC, a signature on every answer
version: 1
---

**DNSSEC** signs a zone's records. The zone's owner holds a private key; each set of records gets a
signature, published as an `RRSIG` record beside it; the public key is published too, as a `DNSKEY`.
A **validating resolver** checks the signature against a key it trusts before believing an answer.

Where the trusted key comes from is what makes this work across the internet. Each parent zone
publishes a fingerprint of its children's keys, so trust flows down from the root, whose key every
validating resolver is configured with. The lab has no root, so the resolver is told to trust the
company's zone key directly, which is the same mechanism with the chain cut short.

`dns` serves the signed zone on port 5300, and `laptop` runs a validating resolver, Unbound, on its
own loopback:

```
ana@laptop:~$ grep -E "server:|trust-anchor|stub-addr" /etc/unbound/unbound.conf
server:
  trust-anchor-file: "/etc/unbound/example.com.key"
  stub-addr: 192.0.2.53@5300
```

The trust anchor is the zone's public key; the stub address tells Unbound where the zone is served.
Asking it for the shop's address, with `+dnssec` so the signature is shown:

```
ana@laptop:~$ dig +dnssec @127.0.0.1 www.example.com | grep -E "flags:|IN.A|RRSIG"
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
; EDNS: version: 0, flags: do; udp: 1232
;www.example.com.		IN	A
www.example.com.	300	IN	A	192.0.2.80
www.example.com.	300	IN	RRSIG	A 13 3 300 20261231000000 20260901000000 63346 example.com. cRghjqyAuxVDYFMyd2M4M+lUN/+pKmeoc8eB2lXcgKHArwkkzPO6J4De M3LZLWAhcLrF6lM0HUOWGfeI458UWA==
```

The answer, `192.0.2.80`, arrives with its `RRSIG`: algorithm 13, which is ECDSA with P-256, valid from
1 September to 31 December 2026, made with the key whose tag the signature names. And in the flags
there is **`ad`, authenticated data**: the resolver checked the signature and says so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"On the left, the chain of trust on the internet: the resolver trusts the root&#x27;s key; the root zone publishes a fingerprint of the .com key; .com publishes a fingerprint of example.com&#x27;s key; example.com&#x27;s key signs its records. On the right, the lab: the resolver on laptop is given example.com&#x27;s key directly as its trust anchor, and that key signs the record www.example.com A 192.0.2.80.\"><defs><marker id=\"dn-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"dn-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">on the internet</text><rect x=\"20\" y=\"34\" width=\"300\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.</text><text x=\"30\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">root key, configured in every resolver</text><rect x=\"20\" y=\"94\" width=\"300\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">com.</text><text x=\"30\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its key, fingerprinted by the root</text><rect x=\"20\" y=\"154\" width=\"300\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com.</text><text x=\"30\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its key, fingerprinted by .com</text><path d=\"M170 80 L170 94\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dn-ah-phosphor)\"></path><path d=\"M170 140 L170 154\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dn-ah-phosphor)\"></path><text x=\"20\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each parent vouches for its child&#x27;s key</text><path d=\"M360 20 L360 235\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"390\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">in the lab</text><rect x=\"390\" y=\"34\" width=\"310\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop: Unbound</text><text x=\"400\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trust anchor: example.com&#x27;s key</text><rect x=\"390\" y=\"154\" width=\"310\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com A 192.0.2.80</text><text x=\"400\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RRSIG made with that key</text><path d=\"M545 80 L545 154\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dn-ah-phosphor)\"></path><text x=\"555\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks the signature</text></svg>", "caption": "The internet's chain starts at the root. The lab's starts at the zone, which is the same check with fewer links."}
```

A client that trusts `ad` is trusting its resolver's word, so the link between the two has to be
trustworthy too: here it is the loopback, on the same machine. Across a network, that last hop needs
protecting too, by encrypting it with DNS over TLS or over HTTPS.
