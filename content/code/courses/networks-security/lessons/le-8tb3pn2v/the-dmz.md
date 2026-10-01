---
title: The DMZ, where the public services live
version: 1
---

Some services exist to be reached from the internet: the shop, the name server that answers for the
company's domain, a mail relay. They cannot be kept out of reach, so they are **kept somewhere a
compromise costs little**. That somewhere is the **DMZ**, named after the demilitarised zone between
two borders: a segment of its own, between the internet and the inside, trusted by neither.

The rule that defines a DMZ is about direction:

- the internet may reach the DMZ, on the services it offers and nothing else;
- the DMZ may reach the inside only where a service needs it, one address and one port at a time;
- **the inside is never reachable from the internet directly**, only through something in the DMZ.

The shop follows it: `remote` reaches `www`, `www` reaches `app` on 8080, and `app` is reached by
nothing else from outside.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two ways to build a DMZ. On the left, one firewall with three legs: the internet, the DMZ and the inside each hang off the same firewall. On the right, two firewalls in a row: the outer one between the internet and the DMZ, the inner one between the DMZ and the inside, so traffic from the internet to the inside crosses both.\"><defs><marker id=\"dz-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">one firewall, three legs</text><rect x=\"110\" y=\"34\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">internet</text><rect x=\"110\" y=\"114\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><rect x=\"20\" y=\"200\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DMZ</text><rect x=\"200\" y=\"200\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">inside</text><path d=\"M170 64 L170 114\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M140 144 L80 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M200 144 L270 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M360 20 L360 240\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"390\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">two firewalls</text><rect x=\"390\" y=\"34\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">internet</text><rect x=\"390\" y=\"94\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">outer fw</text><rect x=\"390\" y=\"154\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DMZ</text><rect x=\"560\" y=\"154\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">inner fw</text><rect x=\"560\" y=\"214\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">inside</text><path d=\"M450 64 L450 94\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M450 124 L450 154\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M510 169 L560 169\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M630 184 L630 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path></svg>", "caption": "The lab is the left-hand shape. The right-hand one trades a second rule set for a second layer."}
```

## One firewall or two

The lab's DMZ hangs off a leg of the same firewall that guards everything else, a **three-legged**
or single-firewall DMZ. The other classic design puts the DMZ **between two firewalls**: an outer one
facing the internet and an inner one guarding the inside, often from different vendors so that one
flaw does not open both.

| | one firewall, three legs | two firewalls |
|---|---|---|
| cost and upkeep | one box, one rule set | two of each |
| a flaw or a wrong rule in the firewall | can open every zone at once | opens one layer; the other still stands |
| where the inside's rules live | in the same table as the internet's | on a box the internet never talks to |

Most small and medium networks use one firewall with several legs, and it is a sound design **if the
rule set is kept disciplined**, which is what the rest of this course is about. The two-firewall
design buys depth at the price of a second policy that has to stay consistent with the first.
