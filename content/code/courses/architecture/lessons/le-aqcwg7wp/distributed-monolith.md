---
title: The distributed monolith
version: 1
---

There is a way to pay the whole bill of the previous section and receive none of what it buys. **A
distributed monolith** is a system split into services that still cannot change, deploy or fail
independently. It has the latency and the partial failures of services and the coupling of a
monolith, and it is the most common result of splitting without naming a force.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Four services in a row, catalogue, orders, stock and payments, joined by synchronous calls in a chain, all reading one shared database below, and all four wrapped by a single dashed box labelled deployed together on the same day.\"><defs><marker id=\"l2-dmono-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l2-dmono-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"30\" width=\"660\" height=\"110\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"46\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">deployed together, on the same day</text><rect x=\"50\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">catalogue</text><path d=\"M182 92 L208 92\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-amber)\"></path><path d=\"M115 122 L115 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"210\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><path d=\"M342 92 L368 92\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-amber)\"></path><path d=\"M275 122 L275 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"370\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><path d=\"M502 92 L528 92\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-amber)\"></path><path d=\"M435 122 L435 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"530\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">payments</text><path d=\"M595 122 L595 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"50\" y=\"164\" width=\"610\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one shared database</text></svg>", "caption": "A distributed monolith: the network costs of services and the coupling of a monolith, at the same time. Each of its three marks is drawn here, the chain, the shared tables and the joint deploy."}
```

It has three marks, and any one of them is enough to suspect it:

**They deploy together.** A change to orders needs a change to stock, released in the same hour,
in a particular order. Teams keep a spreadsheet of which versions work together. The independence
the services exist for is gone.

**They share a database.** The shortcut from the section on owning data. The services look separate in the
repository and are joined at the schema.

**They call each other in long synchronous chains.** A request to the catalogue calls orders, which
calls stock, which calls payments, each waiting for the next. The latency of the request is the sum
of the chain, and its availability is the product: if each of four services answers 99.9% of the
time, the chain answers at most 99.9% to the fourth power, about 99.6%, which is nearly four times
the downtime of any one of them. Lesson 5 works through that arithmetic and the alternative to the
chain.

## How systems end up here

Usually by splitting along technical layers or by noun, before the boundaries were known, and then
finding that every feature crosses every service. Sometimes by splitting a ball of mud directly,
without first making modules, so that the services inherit every tangled dependency the code had.
And sometimes by sharing a library of domain classes between all the services, so that a change to
`Product` is a change to all of them at once.

## Getting out

The way out is the one lesson 1 described: find the real boundaries, and draw them. In practice
that often means **merging services back together** where they always change together, which feels
like going backwards and is the cheapest fix available. Segment's engineering team described doing
exactly that in 2018, folding over a hundred destination services back into one after the
operational cost of keeping them apart outgrew what the split gave them.

**A service that cannot be deployed alone is not a service.** That one test, applied honestly to
each line on the diagram, finds most distributed monoliths before they are built.
