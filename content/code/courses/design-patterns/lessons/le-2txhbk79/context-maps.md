---
title: "Context maps: how the models meet"
version: 1
---

**A context map is a drawing of the bounded contexts and of the relationship between each pair
that talks: who depends on whom, and who adapts when the other changes.** The contexts are the
nouns; the map is about the verbs. It is the strategic document that a new developer needs on their
first day, because it says which changes are theirs to make and which have to be negotiated.

The wrong idea is that integration is a technical detail: an HTTP call here, a shared table there.
Every connection between two models is also a relationship between the people who own them. When
the catalogue renames a field, somebody's code breaks, and the map is where you decide in advance
whose problem that is. In DDD's vocabulary the context that others depend on is **upstream**, and
the one that depends is **downstream**. Changes flow down; complaints flow up.

## The relationships

Evans named most of these, and the names have stuck because each one is a different answer to
"who adapts?":

| relationship | who adapts to whom | when it fits |
|---|---|---|
| partnership | both, together; they succeed or fail as one | two teams that plan their releases jointly |
| shared kernel | nobody alone: a small piece of model is owned by both, and changed only by agreement | a value type both depend on and neither wants to copy |
| customer/supplier | the upstream plans for the downstream's needs | the downstream's needs count in the upstream's plans |
| conformist | the downstream adopts the upstream's model as it is | the upstream will not change for you, and its model is good enough |
| anticorruption layer | the downstream translates the upstream's model into its own | the upstream will not change, and its model would damage yours |
| open host service, published language | the upstream offers one documented protocol for everybody | many downstreams, so one-to-one deals would not scale |
| separate ways | nobody: the two do not integrate at all | the cost of connecting is higher than the benefit |

## The library's map

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-context-map\" aria-label=\"The library's context map. Five boxes: the national bibliographic service and the payment provider, both external, drawn dashed; and the library's own catalogue, lending and acquisitions. An arrow from the bibliographic service down to the catalogue passes through a small box labelled ACL, the anticorruption layer. An arrow from the catalogue to lending is labelled customer/supplier, with U at the catalogue end and D at the lending end. An arrow from the payment provider to lending is labelled conformist. Between the catalogue and acquisitions sits a small box labelled ISBN, the shared kernel, joined to both.\"><defs><marker id=\"l11-context-map-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"65.0\" y=\"20.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"170.0\" y=\"33.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">national bibliographic</text><text x=\"170.0\" y=\"46.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">service</text><rect x=\"465.0\" y=\"20.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">payment provider</text><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">outside the library</text><rect x=\"85.0\" y=\"178.0\" width=\"170.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">catalogue</text><rect x=\"475.0\" y=\"178.0\" width=\"170.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lending</text><rect x=\"85.0\" y=\"282.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">acquisitions</text><path d=\"M170.0 60.0 L170.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"140.0\" y=\"105.0\" width=\"60.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ACL</text><path d=\"M170.0 135.0 L170.0 177.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-context-map-dp-ah-paper-dim)\"></path><text x=\"206.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">anticorruption layer</text><path d=\"M255.0 200.0 L474.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-context-map-dp-ah-paper-dim)\"></path><text x=\"365.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">customer/supplier</text><text x=\"266.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">U</text><text x=\"462.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">D</text><path d=\"M560.0 60.0 L560.0 177.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-context-map-dp-ah-paper-dim)\"></path><text x=\"570.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conformist</text><text x=\"548.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">U</text><text x=\"548.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">D</text><path d=\"M170.0 222.0 L170.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"138.0\" y=\"238.0\" width=\"64.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"170.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ISBN</text><path d=\"M170.0 272.0 L170.0 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"212.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">shared kernel</text><text x=\"560.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">U upstream, D downstream</text></svg>", "caption": "Every line has a name, and the name says who adapts when the other side changes."}
```

Read the map one line at a time.

**Catalogue to lending is customer/supplier.** The lending desk shows titles and authors, so it
depends on the catalogue. The catalogue's owners treat lending as a customer: before changing what
a catalogue entry looks like, they ask what the desk screen needs. Without that agreement the
relationship slides into conformist by default, and lending has no say.

**Catalogue and acquisitions share a kernel: the ISBN.** Both need to parse, validate and format
ISBNs, and two copies of that code would disagree one day about a hyphen. So one small module is
owned by both, and a change to it needs both to agree. A shared kernel works while it stays small;
the moment it grows a `Book` class, it has become the one enterprise model again.

**The payment provider to lending is conformist.** The provider's model of a payment, with its own
statuses for pending, confirmed and refunded, is what it is, and the library is one customer among
thousands. Its model is also reasonable, so lending simply uses its words for payment states. Being
conformist is not a defeat when the upstream model is good; it saves a translation nobody needs.

**The national bibliographic service to catalogue goes through an anticorruption layer.** The
service will not change for one library, and its model is a poor fit: abbreviated field names,
titles in capitals, authors written surname first. Adopting it would put those habits into the
catalogue's own code. The next section builds the layer.

## What the map is for

A map that matches the code is a planning tool. A downstream team can see that it is conformist
and decide whether that is still acceptable. A team about to add an integration can see that it is
creating a new upstream dependency, and choose the relationship before the first line of code
chooses it for them. **The map describes the organisation as much as the software**, which is
Conway's observation from 1968: systems end up shaped like the communication between the teams that
build them.

`architecture-modeling`, the course after this one, draws context maps as models in their own
right. Here a sketch on a page is enough, as long as every line on it has a name from the table.
