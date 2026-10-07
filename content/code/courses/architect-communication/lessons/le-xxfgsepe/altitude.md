---
title: Altitude, jargon and the curse of knowledge
version: 1
---

**Every fact can be stated at several altitudes, from the effect on the business down to the line
of configuration, and a message goes wrong when it is written at the writer's altitude instead of
the reader's.** The writer usually lives near the ground, among the details they have just been
working with. That is the altitude that feels natural, and it is almost never the one the reader
needs.

## The ladder

The linguist S. I. Hayakawa drew this as a *ladder of abstraction*: the same thing named at rising
levels of generality, each rung leaving out more detail and covering more ground. A technical fact
has the same ladder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four stacked rungs stating one fact at falling altitude. The business: about 180 payments fail every Friday evening; the board decides here. The product: checkout fails for 2% of customers at peak; product decides here. The system: route planner and checkout compete for one database; the team decides here. The component: connections on the primary reach the limit; the team decides here.\"><defs><marker id=\"altitude-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"20\" width=\"520\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the business</text><text x=\"44\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">about 180 payments fail every Friday evening</text><text x=\"600\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the board</text><rect x=\"60\" y=\"86\" width=\"490\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the product</text><text x=\"74\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">checkout fails for 2% of customers at peak</text><text x=\"600\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">product</text><rect x=\"90\" y=\"152\" width=\"460\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"104\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the system</text><text x=\"104\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">route planner and checkout compete for one database</text><text x=\"600\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the team</text><rect x=\"120\" y=\"218\" width=\"430\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"134\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the component</text><text x=\"134\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">connections on the primary reach the limit</text><text x=\"600\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the team</text><text x=\"30\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one fact, four rungs: the reader's decision says which one to start on</text><text x=\"600\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">decides here</text></svg>", "caption": "The same fact on four rungs of the ladder. A message starts on the rung where its reader decides and goes down only to support a claim."}
```

None of the rungs is the right one in general. **The right rung is the one where the reader's
decision lives.** The board decides on the top rung; Renata between the first and the second; Bruna's
team on the third and fourth. A message can move between rungs, and the good ones do it on purpose:
start where the reader decides, and go down one rung only to support a claim they might doubt.

The failure has a recognisable shape: a message to the CEO that starts on the bottom rung, with a
configuration parameter, and climbs slowly towards the effect. By the time it reaches revenue, the
reader has gone.

## The curse of knowledge

Why do writers stay on their own rung? In 1990 Elizabeth Newton, a psychology student at Stanford,
asked people to tap out the rhythm of a well-known song on a table while a listener tried to name
it. Before starting, the tappers predicted that half of the listeners would guess the song. Out of
120 songs tapped, the listeners named 3.

The tappers could hear the melody in their heads while they tapped. They could not imagine hearing
only the knocking. **Once you know something, it is very hard to remember what it was like not to
know it**, and that gap is what economists, who named it first, call the *curse of knowledge*.

Jargon is its most visible symptom. "Replica lag", "connection pool", "p95" feel like plain words
to the person who uses them daily. Three habits help:

- **Define a term the first time, or do not use it.** "A replica, a read-only copy of the database
  kept up to date automatically" costs a line. If the reader will never meet the term again, skip
  it and say what it does.
- **Replace the acronym with what it stands for**, unless the reader uses the acronym themselves.
  Renata says "SLA" every day; Caio does not say "p95".
- **Ask somebody from the audience to read it.** This is pass 6 from lesson 1, and it is the only
  reliable cure, because the curse is invisible from the inside.

## Analogies, and where they break

An analogy lets a reader borrow intuition from something they already know. "The database is a
shop with one till; on Friday evenings the route planner joins the queue with a trolley of two
hundred items" makes the problem clear to anybody who has been to a supermarket.

**Every analogy breaks somewhere, and the reader will reason from the broken part.** Extend the
shop and the obvious fix is "open another till", which in database terms sounds like the larger
server, the alternative Lívia's proposal rejected. A good analogy is used for one point and then
dropped, or its limit is stated: "the analogy stops here: the replica is not a second till, it is
a second shop with a copy of the shelves, a few seconds out of date".
