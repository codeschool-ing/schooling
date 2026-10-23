---
title: ArchiMate: one notation across the layers
version: 1
---

**ArchiMate is The Open Group's modelling language for enterprise architecture: a notation in which
business, application and technology elements, and the relationships between them, can be drawn in
one diagram with a precise meaning.** It is to enterprise architecture what UML is to software
design, and it is TOGAF's natural partner. The current version is 3.2, from 2023.

## Layers and aspects

ArchiMate's core arranges its elements on two axes:

- **layers**: **business**, **application** and **technology**, matching the domains of lesson 8;
- **aspects**: **active structure** (who or what does something: an actor, a component, a node),
  **behaviour** (what is done: a process, a function, a service) and **passive structure** (what it is
  done to: a business object, a data object, an artefact).

Further elements cover motivation (goals, principles, requirements), strategy (capabilities) and
implementation and migration (work packages, plateaus), which line up with TOGAF's phases A, E and F.

## A small view of Carcará

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l09-archimate\" aria-label=\"A small ArchiMate view of Carcará in three layers. Business layer: the passenger, a business actor, assigned to the business process buy a ticket. Application layer: the application service ticket sales serves the process; the application component ticketing realises the service and accesses the data object booking. Technology layer: the technology service container runtime serves ticketing, and is realised by the node container cluster.\"><defs><marker id=\"l09-archimate-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l09-archimate-am-hollow-paper\" viewBox=\"0 0 12 10\" refX=\"11\" refY=\"5\" markerWidth=\"11\" markerHeight=\"10\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M1 1 L11 5 L1 9 z\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.1\"></path></marker><marker id=\"l09-archimate-am-open-paper\" viewBox=\"0 0 10 8\" refX=\"9.5\" refY=\"4\" markerWidth=\"9\" markerHeight=\"8\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0.5 L9.5 4 L0 7.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></path></marker></defs><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"112.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"22.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">Business</text><rect x=\"10.0\" y=\"130.0\" width=\"700.0\" height=\"112.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"22.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Application</text><rect x=\"10.0\" y=\"250.0\" width=\"700.0\" height=\"112.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"22.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Technology</text><rect x=\"120.0\" y=\"40.0\" width=\"140.0\" height=\"50.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><circle cx=\"244.0\" cy=\"52.0\" r=\"4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><path d=\"M244.0 56.0 L244.0 63.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M239.0 59.0 L249.0 59.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"182.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Passenger</text><rect x=\"400.0\" y=\"40.0\" width=\"170.0\" height=\"50.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M542 50 L556 50 L562 56 L556 62 L542 62 L548 56 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"470.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Buy a ticket</text><circle cx=\"262.0\" cy=\"65.0\" r=\"3\" fill=\"var(--paper)\"></circle><path d=\"M265.0 65.0 L398.0 65.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-archimate-am-fill-paper)\"></path><text x=\"330.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">assignment</text><rect x=\"400.0\" y=\"140.0\" width=\"170.0\" height=\"36.0\" rx=\"18\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ticket sales</text><path d=\"M485.0 140.0 L485.0 92.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-archimate-am-open-paper)\"></path><text x=\"478.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">serving</text><rect x=\"400.0\" y=\"206.0\" width=\"170.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"552.0\" y=\"210.0\" width=\"12.0\" height=\"9.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></rect><text x=\"476.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing</text><path d=\"M470.0 206.0 L470.0 178.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-archimate-am-hollow-paper)\"></path><text x=\"462.0\" y=\"192.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">realises</text><rect x=\"150.0\" y=\"196.0\" width=\"130.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M150.0 208.0 L280.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"215.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Booking</text><path d=\"M400.0 221.0 L282.0 221.0\" stroke=\"var(--paper)\" stroke-width=\"1.1\" fill=\"none\" stroke-dasharray=\"2 3\" marker-end=\"url(#l09-archimate-am-open-paper)\"></path><text x=\"340.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">accesses</text><rect x=\"400.0\" y=\"268.0\" width=\"170.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Container runtime</text><path d=\"M485.0 268.0 L485.0 236.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-archimate-am-open-paper)\"></path><text x=\"478.0\" y=\"254.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">serving</text><path d=\"M410.0 322.0 L420.0 312.0 L570.0 312.0 L570.0 338.0 L560.0 348.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--ink)\"></path><path d=\"M560.0 322.0 L570.0 312.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"410.0\" y=\"322.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"485.0\" y=\"335.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Container cluster</text><path d=\"M485.0 322.0 L485.0 304.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-archimate-am-hollow-paper)\"></path><text x=\"392.0\" y=\"315.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">realises</text></svg>", "caption": "Each shape is a type of element and each line a type of relationship, both defined by the specification. Serving and realisation are as different here as composition and aggregation were in UML."}
```

Read it from the top:

- the **passenger**, a business actor, is assigned to the business process **buy a ticket**;
- that process is **served by** the application service **ticket sales**;
- the service is **realised by** the application component **ticketing**;
- ticketing **accesses** the data object **booking**;
- ticketing runs on the **container cluster**, a technology node, whose technology service serves it.

The figure shows what makes ArchiMate different from a box diagram: **every element has a type shown
by its shape, every relationship has a type shown by its line**, and the types are defined in the
specification. *Serves* and *realises* are not interchangeable, any more than lesson 2's composition
and aggregation are.

## A few relationships

| relationship | drawn as | means |
| --- | --- | --- |
| **serving** | solid line, open arrowhead | an element provides its functionality to another |
| **realisation** | dashed line, hollow triangle | an element brings another, more abstract one into being |
| **assignment** | solid line, a dot at the source and an arrowhead | who or what performs a behaviour |
| **access** | dotted line, small arrowhead | a behaviour reads or writes a passive element |
| **composition** | solid line, filled diamond | the part belongs to the whole |
| **triggering** | solid line, filled arrowhead | one behaviour causes the next |

## Where it fits

ArchiMate is worth learning when you work at the enterprise level, especially where TOGAF is in use
and models are kept in a tool such as Archi, a free modelling tool, or one of the commercial
repositories. For a single system, **C4 and UML say what an engineering team needs with less
vocabulary**. The two can coexist: Carcará's enterprise view is in ArchiMate, and each application
on it links to its C4 diagrams.
