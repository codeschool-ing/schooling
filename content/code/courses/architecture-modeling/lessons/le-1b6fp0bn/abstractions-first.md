---
title: Abstractions first, notation second
version: 1
---

**The C4 model is a small set of abstractions for describing software, and a set of diagrams that
show them at four levels of detail.** Simon Brown developed it from his teaching in the late 2000s,
and published it under that name around 2011. Its premise is that most architecture diagrams fail
not because the shapes are wrong, but because nobody agreed on what the boxes are.

So C4 starts with the vocabulary, and only then with the pictures.

## Five words

| | what it is | Carcará example |
| --- | --- | --- |
| **person** | a human user of the system, in a role | a passenger, a station agent, a driver |
| **software system** | the highest level of abstraction: something that delivers value to its users, usually owned by one team or organisation | *Carcará ticketing*; the payment company's gateway; *Frota*, the fleet system |
| **container** | an application or a data store that has to be running for the system to work | the passenger web app, the ticketing API, the booking database |
| **component** | a grouping of related functionality behind an interface, inside one container | the booking service inside the ticketing API |
| **code** | the classes, functions and tables that implement a component | `Booking`, `BookingRepository` |

The words nest. **A software system is made of containers; a container is made of components; a
component is implemented by code.** That nesting is what gives the four diagrams their zoom levels:
each diagram takes one box from the level above and opens it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l03-zoom\" aria-label=\"The four C4 levels as successive zooms. Level 1, system context: one box for Carcará ticketing among people and other systems. Level 2, containers: the box opens into apps, an API and data stores. Level 3, components: one container, the ticketing API, opens into its main parts. Level 4, code: one component opens into classes. Each level takes one box of the level above and shows what is inside.\"><defs><marker id=\"l03-zoom-am-fill-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"14.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"94.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · System context</text><text x=\"94.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for everybody</text><rect x=\"64.0\" y=\"85.0\" width=\"60.0\" height=\"30.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><rect x=\"20.0\" y=\"46.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M46.0 62.0 L64.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"140.0\" y=\"46.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M142.0 62.0 L124.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20.0\" y=\"136.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M46.0 138.0 L64.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"140.0\" y=\"136.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M142.0 138.0 L124.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M176.0 100.0 L190.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l03-zoom-am-fill-amber)\"></path><rect x=\"192.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · Containers</text><text x=\"272.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for technical people</text><rect x=\"206.0\" y=\"40.0\" width=\"132.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"218.0\" y=\"54.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"282.0\" y=\"54.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.0\" y=\"89.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"218.0\" y=\"124.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"282.0\" y=\"124.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"247.0\" y=\"86.0\" width=\"50.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><rect x=\"250.0\" y=\"89.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M354.0 100.0 L368.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l03-zoom-am-fill-amber)\"></path><rect x=\"370.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 · Components</text><text x=\"450.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for the container's team</text><rect x=\"384.0\" y=\"40.0\" width=\"132.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"398.0\" y=\"52.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"52.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"90.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"90.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"428.0\" y=\"128.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M532.0 100.0 L546.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l03-zoom-am-fill-amber)\"></path><rect x=\"548.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 · Code</text><text x=\"628.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rarely drawn</text><rect x=\"562.0\" y=\"40.0\" width=\"132.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"570.0\" y=\"52.0\" width=\"52.0\" height=\"36.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><path d=\"M570.0 64.0 L622.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"634.0\" y=\"52.0\" width=\"52.0\" height=\"36.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><path d=\"M634.0 64.0 L686.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"602.0\" y=\"112.0\" width=\"52.0\" height=\"36.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><path d=\"M602.0 124.0 L654.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Each diagram opens one box of the diagram before it. The audience narrows as the detail grows."}
```

## Notation independent

C4 does not prescribe shapes or colours. A container can be a rectangle, a cylinder for a database,
or a phone outline for a mobile app. What it does prescribe is that **every element carries its
name, its type, its technology where it has one, and a short description**, and that **every
relationship carries a label saying what it does and, where useful, the technology it uses**.
Lesson 1's reading test asked for the same things; C4 makes them the default rather than the
exception.

Because of that, a C4 diagram needs a legend like any other. The common convention, used in this
lesson, is a rounded box with a head for a person, boxes in one colour for elements inside the
system being described, and grey for everything outside it.

## Why it caught on

Two reasons explain why C4 became the default answer to *how should we draw our architecture?* in
many teams that had given up on UML:

- **It matches how engineers already talk.** "The app calls the API, which writes to the database"
  is a container diagram in words. Nobody has to learn what a node or an execution environment is.
- **It separates the audiences.** The context diagram is for anybody, the container diagram for
  technical people, the component diagram for the team that owns one container. Lesson 14 relies on
  this when it chooses a picture per audience.

It borrows freely: a component diagram in C4 is close to a UML component diagram without the balls
and sockets, and the code level, when it is drawn, is usually a UML class diagram. Learning both is
not duplication. **C4 decides what to draw at each level; UML says precisely how to draw some of
it.**
