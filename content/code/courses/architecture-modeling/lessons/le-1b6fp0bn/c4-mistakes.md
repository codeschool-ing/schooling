---
title: How C4 diagrams go wrong, and a checklist
version: 1
---

**Most C4 mistakes come from breaking the vocabulary**: a box that is a different kind of thing from
its neighbours, a level that shows the level below it, a line that says nothing. The notation is
free; the words are not.

## Five common mistakes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-c4-wrong\" aria-label=\"A container diagram with five mistakes, numbered. One: a box named booking service, a component, among containers. Two: a load balancer and a Kubernetes cluster drawn as containers. Three: two APIs, ticketing and back office, both writing to one database, with no owner named. Four: every line labelled uses. Five: a box named ticketing with no type and no technology.\"><defs><marker id=\"l03-c4-wrong-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"38.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Load balancer</text><text x=\"90.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"20.0\" y=\"138.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"153.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Kubernetes cluster</text><text x=\"90.0\" y=\"166.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"260.0\" y=\"38.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing</text><rect x=\"255.0\" y=\"138.0\" width=\"150.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"153.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Booking service</text><text x=\"330.0\" y=\"166.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Component]</text><rect x=\"485.0\" y=\"38.0\" width=\"150.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Back-office API</text><text x=\"560.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container: Kotlin]</text><path d=\"M395.0 217.0 L395.0 263.0 A75.0 7 0 0 0 545.0 263.0 L545.0 217.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"var(--panel)\"></path><ellipse cx=\"470.0\" cy=\"217.0\" rx=\"75.0\" ry=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></ellipse><text x=\"470.0\" y=\"238.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Shared database</text><text x=\"470.0\" y=\"249.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"7.5\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><path d=\"M160.0 60.0 L258.0 60.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">uses</text><path d=\"M90.0 82.0 L90.0 136.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"98.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">uses</text><path d=\"M330.0 82.0 L330.0 136.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"338.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">uses</text><path d=\"M370.0 182.0 L440.0 210.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"414.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">uses</text><path d=\"M560.0 82.0 L500.0 208.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-c4-wrong-am-fill-paper)\"></path><text x=\"536.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">uses</text><circle cx=\"330.0\" cy=\"196.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"330.0\" y=\"196.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">1</text><circle cx=\"20.0\" cy=\"110.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"20.0\" y=\"110.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">2</text><circle cx=\"560.0\" cy=\"240.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"560.0\" y=\"240.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3</text><circle cx=\"250.0\" cy=\"46.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"250.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">4</text><circle cx=\"410.0\" cy=\"40.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"410.0\" y=\"40.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">5</text></svg>", "caption": "Each box and line is drawable in any tool and wrong in C4's vocabulary. The checklist in this section finds all five."}
```

1. **Mixed levels.** The *Booking service*, a component, sits on the container diagram beside the
   database. A reader cannot tell which boxes run on their own and which live inside something else.
2. **Infrastructure as containers.** The *load balancer* and the *Kubernetes cluster* are drawn as
   containers. They are where containers run, which belongs on a deployment diagram.
3. **The shared database with no owner.** Two APIs write to the same database, and nothing says
   which owns it. The picture is accurate and hides the most important fact about it: that schema
   changes now need two teams.
4. **Lines that say *uses*.** Every arrow carries the same verb, so the diagram shows that things are
   connected and not why.
5. **Missing types and technology.** *Ticketing* with no `[Container: Kotlin]` could be a service, a
   team, a database schema or the whole system.

## The review checklist

C4's own website publishes a short review checklist. In the spirit of it, these are the questions
for any C4 diagram, and they extend the reading test of lesson 1:

| about | question |
| --- | --- |
| **the diagram** | Does it have a title saying the level and the scope? Is there a key? Is the scope, one system or one container, clear? |
| **each element** | Does it have a name, a type, a technology where relevant, and a description? Is it the right kind of thing for this level? |
| **each relationship** | Does it have a description of intent? A technology, if the reader is technical? A direction that matches the description? |
| **across levels** | Is every element traceable to the level above? Does every relationship at one level appear, explained, at the level below? |

## Container or component: the hard cases

A few cases come up in every team:

- **A serverless function** is a container: it runs and is deployed on its own.
- **A library shared by two services** is a component of each, or code, not a container: it never
  runs by itself.
- **A schema inside a shared database server** is its own data-store container if it is owned and
  used separately; the database *server* is infrastructure.
- **A modular monolith** is one container whose modules are components, which is the whole point of
  the style: the boundaries exist inside one deployable unit.

**Draw it yourself.** Take the wrong diagram in this section and redraw it correctly: decide the
level, remove what belongs elsewhere, and write a real verb on every line.
