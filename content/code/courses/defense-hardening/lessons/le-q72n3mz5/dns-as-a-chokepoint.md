---
title: Every connection starts with a name
version: 1
---

**Before a program connects to anything, it almost always asks for a name.** A browser opening a
phishing page, a mail client fetching an attachment link, a piece of malware calling home: each one
turns a name into an address first, and on a company network that question goes to one place, the
company's resolver. That makes the resolver a chokepoint, a single spot every outbound conversation
passes through before it starts, and a chokepoint is where a defender puts a control.

The common picture of blocking a bad site is a firewall rule with its address in it. That works for
one address on one day. Addresses move, a single name can answer with dozens of them, and a
firewall cannot tell which site a visitor meant when a hundred sites share one address. **The name
is the stable part**, and a resolver that refuses to answer for a name stops every program on every
machine that asks it, without touching any of them.

This lesson builds that control twice over. First the firm gets a resolver of its own on `dns`,
which every machine asks. Then the resolver gets a list of names it will not answer honestly,
and the answers it gives instead point at a **sinkhole**: a machine that receives whatever was
going to the dangerous site, and so tells you which of your machines tried to go there.

## Who desk asks today

Start the lab for this lesson:

```sh
sudo bash hostlab.sh up dns desk trap
```

Then ask `desk` where its questions go:

```
ana@desk:~$ cat /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:2 attempts:3
ana@desk:~$ dig web.jatoba.example | tail -2
;; UDP setup with 8.8.4.4#53(8.8.4.4) for web.jatoba.example failed: network unreachable.
;; no servers could be reached
```

`desk` asks Google's public resolvers, `8.8.8.8` and `8.8.4.4`, and cannot reach them, because
nothing in the lab reaches the internet. Those two lines are not a choice anybody at Jatobá made:
the container copied them from the computer it runs on when it booted, so on your computer they
may name something else. That is the first finding, and it is the ordinary state of a small office:
every machine asks whoever its operating system or its home router told it to ask, and the firm
sees none of those questions.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l14-chokepoint\" aria-label=\"Two drawings of the same office. Above, before the lesson: desk, web and a laptop each send their name questions straight to resolvers outside the firm, and the firm sees none of them. Below, after: every machine asks dns, the firm's resolver, which keeps a log and forwards what it cannot answer to the internet.\"><defs><marker id=\"l14-chokepoint-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-chokepoint-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-chokepoint-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">before: each machine asks whoever it was told to</text><rect x=\"30.0\" y=\"40.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><path d=\"M85.0 74.0 L560.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-amber)\"></path><rect x=\"160.0\" y=\"40.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M215.0 74.0 L560.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-amber)\"></path><rect x=\"290.0\" y=\"40.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">laptop</text><path d=\"M345.0 74.0 L560.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-amber)\"></path><rect x=\"560.0\" y=\"76.0\" width=\"140.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the internet</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">after: one resolver, one log</text><rect x=\"30.0\" y=\"172.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><path d=\"M85.0 206.0 L425.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-phosphor)\"></path><rect x=\"160.0\" y=\"172.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M215.0 206.0 L455.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-phosphor)\"></path><rect x=\"290.0\" y=\"172.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">laptop</text><path d=\"M345.0 206.0 L485.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-phosphor)\"></path><rect x=\"400.0\" y=\"222.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dns</text><text x=\"460.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">logs every question</text><rect x=\"560.0\" y=\"224.0\" width=\"140.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the internet</text><path d=\"M520.0 243.0 L560.0 243.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-chokepoint-dh-ah-paper-dim)\"></path></svg>", "caption": "A resolver of your own is the one place every outbound conversation passes before it starts."}
```

A resolver of your own fixes both halves at once. It gives every machine the same answers, and it
writes down every question, which lesson 18 will treat as part of the inventory of what each
machine does.
