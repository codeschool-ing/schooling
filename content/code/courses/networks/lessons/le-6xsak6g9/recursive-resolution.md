---
title: From the root to the answer
version: 1
---

The resolver did not know `www.example.com` either. It found out by asking, and `dig +trace` repeats
the walk itself, printing each step:

```
ana@laptop:~$ dig +trace www.example.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> +trace www.example.com
;; global options: +cmd
.                       86400   IN      NS      a.root-servers.test.
;; Received 76 bytes from 198.51.100.53#53(198.51.100.53) in 4 ms

com.                    172800  IN      NS      a.gtld-servers.test.
;; Received 124 bytes from 192.0.2.10#53(a.root-servers.test) in 0 ms

example.com.            172800  IN      NS      ns1.example.com.
;; Received 106 bytes from 192.0.2.20#53(a.gtld-servers.test) in 0 ms

www.example.com.        300     IN      A       192.0.2.80
example.com.            3600    IN      NS      ns1.example.com.
;; Received 122 bytes from 192.0.2.53#53(ns1.example.com) in 0 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"How the name www.example.com was resolved. 1: the laptop asks its resolver, 198.51.100.53, for www.example.com. 2: the resolver asks the root server, which answers with a referral: ask the .com servers. 3: the resolver asks the .com server, which refers it on: ask ns1.example.com. 4: the resolver asks ns1.example.com, which answers with the address, 192.0.2.80, and a TTL of 300 seconds. 5: the resolver passes the address back to the laptop and keeps it in its cache.\"><defs><marker id=\"rs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"107\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"32\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks one question</text><rect x=\"260\" y=\"107\" width=\"190\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">resolver</text><text x=\"272\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.53, does the work</text><rect x=\"560\" y=\"20\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rootns</text><text x=\"572\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the root, .</text><rect x=\"560\" y=\"107\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tldns</text><text x=\"572\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.com</text><rect x=\"560\" y=\"194\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ns1</text><text x=\"572\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">example.com</text><path d=\"M160 122 L258 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\"></path><circle cx=\"209\" cy=\"122\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"209\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><path d=\"M258 138 L162 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\"></path><circle cx=\"209\" cy=\"138\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"209\" y=\"138.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">5</text><path d=\"M450 118 L558 43\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\" marker-start=\"url(#rs-ah)\"></path><circle cx=\"504.0\" cy=\"80.5\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"504.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><path d=\"M450 128 L558 130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\" marker-start=\"url(#rs-ah)\"></path><circle cx=\"504.0\" cy=\"129.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"504.0\" y=\"129.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><path d=\"M450 138 L558 217\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rs-ah)\" marker-start=\"url(#rs-ah)\"></path><circle cx=\"504.0\" cy=\"177.5\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"504.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4</text><text x=\"20\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  laptop → resolver: www.example.com?</text><text x=\"20\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  root → resolver: ask the .com servers</text><text x=\"20\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  .com → resolver: ask ns1.example.com</text><text x=\"380\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  ns1 → resolver: 192.0.2.80, TTL 300</text><text x=\"380\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  resolver → laptop: 192.0.2.80</text></svg>", "caption": "The laptop asks once and the resolver does the walking: root, then the top-level domain, then the domain's own server. Only the last one knows the answer; the others only know who to ask next."}
```

1. The resolver is asked which servers answer for `.`, the root. The answer is
   `a.root-servers.test`. (The real internet has thirteen root server names, `a.root-servers.net` to
   `m.root-servers.net`; the lab has one.)
2. **The root does not know `www.example.com`.** It knows who runs `.com`, and says so:
   `a.gtld-servers.test`.
3. The `.com` server does not know it either. It knows who runs `example.com`: `ns1.example.com`.
4. `ns1.example.com` knows. The answer is the `A` record, `192.0.2.80`, TTL 300.

Each server in the chain answers only for its own part of the name, and **hands the rest down**. That
is **delegation**, and it is what lets DNS be run by millions of organisations without any of them
holding the whole thing. A server that refers you on sends a *referral* rather than an answer. Asking
the root directly, with recursion switched off, shows one:

```
ana@laptop:~$ dig @192.0.2.10 www.example.com +norecurse

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> @192.0.2.10 www.example.com +norecurse
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 30762
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: ab20c6e566ce2d13010000006ab6a3bb71d088f054d63a40 (good)
;; QUESTION SECTION:
;www.example.com.               IN      A

;; AUTHORITY SECTION:
com.                    172800  IN      NS      a.gtld-servers.test.

;; ADDITIONAL SECTION:
a.gtld-servers.test.    86400   IN      A       192.0.2.20

;; Query time: 0 msec
;; SERVER: 192.0.2.10#53(192.0.2.10) (UDP)
;; WHEN: Fri Sep 25 13:39:23 -03 2026
;; MSG SIZE  rcvd: 124
```

`ANSWER: 0`, and the `AUTHORITY` section names the `.com` server, with its address in `ADDITIONAL`
so the resolver does not have to look that up too. The resolver walks this chain once and then
remembers every step: the next question about any `.com` name starts at step 3.
