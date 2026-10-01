---
title: Three kinds of denial, three places to stop them
version: 1
---

A **denial of service** makes a service unavailable to the people entitled to use it. Nothing needs
to be stolen or broken into: it is enough to use up something the service needs. When the traffic
comes from many machines at once, usually thousands of compromised devices, it is **distributed**,
a DDoS.

What gets used up decides the kind of attack, and the kind decides where it can be stopped:

| kind | what it exhausts | measured in | where it is absorbed |
|---|---|---|---|
| **volumetric** | the bandwidth of the link into the network | bits per second | upstream: the provider, a scrubbing service, a CDN |
| **protocol** | a table in a device: half-open connections, conntrack entries | packets per second | the firewall and the server's TCP stack |
| **application** | the application's work: pages rendered, queries run | requests per second | the proxy, the application, a cache |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The path of traffic into the company, left to right: the provider&#x27;s network, the company&#x27;s link, the firewall, the proxy and the application. Under each, what it can absorb. A volumetric flood has to be stopped in the provider&#x27;s network, before the link; a protocol attack at the firewall and the servers&#x27; TCP stacks; an application flood at the proxy and the application.\"><defs><marker id=\"dd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dd-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">provider</text><rect x=\"170\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the link</text><rect x=\"320\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><rect x=\"460\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><rect x=\"600\" y=\"40\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><path d=\"M130 55 L170 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><path d=\"M280 55 L320 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><path d=\"M430 55 L460 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><path d=\"M570 55 L600 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><rect x=\"20\" y=\"110\" width=\"250\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">volumetric: before the link fills</text><rect x=\"320\" y=\"110\" width=\"240\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">protocol: tables and TCP stacks</text><rect x=\"460\" y=\"160\" width=\"240\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">application: proxy, cache, the code</text><text x=\"158\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the defender&#x27;s side starts here</text><path d=\"M150 22 L150 100\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Each kind of attack is absorbed where it is still small compared with what is there."}
```

**The most important row is the first**, because it is the one a defender cannot fix at home. If the
link into the building carries 1 Gbit/s and 20 Gbit/s arrive, the firewall never gets to decide
anything: the packets are lost on the provider's side of the cable, the good ones with them. No rule
on `fw` changes that. The next three sections deal with what the defender's own equipment can
absorb, and the last one with what it cannot.

## Denial is not always an attack

The same exhaustion happens by accident: a sale announced by e-mail to a million customers, a
misconfigured client retrying in a tight loop, a partner's integration sent live on a Friday. A
defence that cannot tell a surge of real customers from an attack is still worth having, as long as
it fails in a way that keeps some customers served rather than none. That is the thread through the
controls that follow.
