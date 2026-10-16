---
title: What "eventually" promises, and what it leaves out
version: 1
---

A system is **eventually consistent** when one thing is guaranteed: if the writes stop, every copy of
the data ends up with the same value. Werner Vogels put it that way in 2008, writing about the stores
behind Amazon's shop, and the definition has not changed since.

Read it again for what it leaves out. It does not say **how long** "eventually" is: a second, an hour,
or for as long as a consumer is down. It does not say **what a reader sees** in the meantime, or in
what order. And it does not say **what happens when two copies are changed at once**, beyond the
promise that they will agree in the end on something.

The opposite end is called **strong consistency**, or, in its strictest form, **linearizability**: once
a write has returned, every read anywhere sees it, as if there were a single copy. The previous lesson
showed what that costs. A system that keeps it refuses to answer when it cannot be sure, and waits a
round trip on every commit when nothing is wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines, the stock service above and the shop&#x27;s copy below. At the first mark the stock service changes coffee from 12 to 11. The event reaches the copy two seconds later. Every read of the copy between the two marks answers 12. That stretch is the inconsistency window.\"><defs><marker id=\"l9-window-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9-window-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l9-window-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M250 172 L510 172\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"380\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the window: reads here answer 12</text><text x=\"30\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><text x=\"30\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop b</text><path d=\"M100 62 L690 62\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-wire)\"></path><path d=\"M100 142 L690 142\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-wire)\"></path><text x=\"150\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">12</text><text x=\"380\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">11</text><text x=\"170\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">12</text><text x=\"600\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">11</text><circle cx=\"250\" cy=\"62\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"510\" cy=\"142\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><path d=\"M254 67 L505 137\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-window-ah-phosphor)\"></path><text x=\"250\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">PUT 11</text><text x=\"560\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">event applied</text><path d=\"M300 170 L300 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><path d=\"M360 170 L360 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><path d=\"M420 170 L420 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><path d=\"M470 170 L470 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l9-window-ah-amber)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "The window is the time between the owner changing and the copy hearing about it. Every read inside it gets the old value, and nothing on the screen says so."}
```

## It is already in the course

The course has met it twice already. Lesson 5 listed a way for the shop to know the stock without
asking: the stock service publishes an event each time a count changes, and the shop keeps its own
copy, a little behind. This lesson builds exactly that. And in lesson 8 the asynchronous standby
answered reads with a value the primary had already changed.

It also turns up in places nobody designs as "a copy". A **read replica** behind a database. A
**cache** in front of a service. A **search index** fed from the database, which lesson 17 builds. A
**CDN** holding yesterday's page. A **report** built every night. Each one answers from a copy that
the owner updates afterwards, and each one has a window in which the copy is wrong.

## What the lesson covers

"Eventually" is the easy part. The lesson is about what sits around it, and each item gets a section:

| question "eventually" leaves open | the section |
| --- | --- |
| how long is the window, and what makes it longer | the window |
| does a person see their own change | read-your-writes |
| can a person see time go backwards | monotonic reads |
| can a late event undo a newer one | order and convergence |
| what happens when two places change one thing | last writer wins |
| what the screen should say about all this | telling the customer |

The guarantees in the middle of the table have names because Douglas Terry and his colleagues gave
them names in 1994, for a system called Bayou: **session guarantees**, promises made to one user about
what that user sees, cheaper than strong consistency for everybody. They are what makes an eventually
consistent system feel consistent to the person in front of it.
