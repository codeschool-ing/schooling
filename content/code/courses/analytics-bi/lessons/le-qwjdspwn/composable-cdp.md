---
title: Packaged or composable
version: 1
---

A **customer data platform**, or CDP, is the product category all three now sell into: one place that
knows every customer, builds lists of them, and sends those lists to every tool. There are two ways to
build one, and the difference is **where the customer profile lives**.

A **packaged CDP** keeps its own copy. Events arrive, the product resolves identities, stores a profile
per person in its own database, and builds audiences there. The warehouse may receive a copy too, but
the profile the tools are fed from is the vendor's. This is how Segment's event collection and its
profiles grew up.

A **composable CDP** keeps no copy of its own. The profile is a model in the company's warehouse — like
`activation.crm_contacts` — and the product reads it, builds audiences on top of it and sends them out.
Hightouch describes itself this way, and Census made the same argument before Fivetran bought it: the warehouse is the
store, and the product is the arrow out of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"two-cdps\" aria-label=\"Two diagrams side by side. On the left, a packaged CDP: the website and the app send events to the CDP, which keeps its own store of customer profiles and sends audiences to the tools; the warehouse receives a copy, drawn dashed. On the right, a composable CDP: the website and the app send events to the warehouse, where the profile is a model; the product reads the model, keeps no copy, and sends audiences to the tools.\"><defs><marker id=\"two-cdps-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">packaged</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">composable</text><line x1=\"360\" y1=\"15\" x2=\"360\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"20\" y=\"50\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">website, app</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CDP</text><text x=\"270.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own copy</text><text x=\"270.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">of every profile</text><rect x=\"200\" y=\"240\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the tools</text><rect x=\"20\" y=\"180\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"80.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">warehouse</text><line x1=\"140\" y1=\"70\" x2=\"198\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#two-cdps-ah)\"></line><line x1=\"270\" y1=\"160\" x2=\"270\" y2=\"238\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#two-cdps-ah)\"></line><line x1=\"198\" y1=\"140\" x2=\"142\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#two-cdps-ah)\"></line><text x=\"70\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">a copy</text><rect x=\"380\" y=\"50\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">website, app</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">warehouse</text><text x=\"630.0\" y=\"87.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">profile = a model</text><rect x=\"560\" y=\"160\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the product</text><rect x=\"560\" y=\"240\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the tools</text><line x1=\"500\" y1=\"70\" x2=\"558\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#two-cdps-ah)\"></line><line x1=\"630\" y1=\"120\" x2=\"630\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#two-cdps-ah)\"></line><line x1=\"630\" y1=\"200\" x2=\"630\" y2=\"238\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#two-cdps-ah)\"></line><text x=\"470\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">reads, keeps no copy</text></svg>", "caption": "The question that separates them is where the customer profile is kept: in the vendor's store, or as a model in the company's warehouse."}
```

Neither is better in general. What each costs is different:

| | packaged | composable |
|---|---|---|
| where *net revenue* is defined | in the CDP's settings, again | in the semantic layer, once (lesson 3) |
| a second copy of personal data | yes, at the vendor | no, though rows pass through the vendor on the way to a tool |
| what you need first | an account and the snippets in the site | a warehouse with the data already modelled |
| who can build an audience | marketing, in the CDP | marketing too, on models somebody in data wrote |

The second row is the one an LGPD review asks about. A composable product still reads the rows and sends
them to the destination, so it is still processing personal data on the company's behalf and still
needs the contract of lesson 7; what it avoids is keeping a second, complete set of profiles somewhere
nobody erases from.

The first row is the one this course has argued for since lesson 3. A company with a semantic layer has
already done the expensive half of a composable CDP. A company without one, buying a packaged CDP,
will define its customer for the third time.
