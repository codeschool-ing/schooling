---
title: Growing designers
version: 1
---

An architect who designs everything well has built a company that can design only as fast as one
person. **The lasting part of the job is raising the number of people at Carreto who can make a
sound structural decision without Renata in the room.** The common belief is that this happens by
itself, as developers watch good designs go past. Watching teaches recognition. Designing teaches
design, and the only way to learn it is to do it with somebody checking the work.

Three practices carry most of it at Carreto: letting other people write the decision records,
designing in pairs, and running katas. A fourth idea ties them together, which is handing a kind of
decision over in steps rather than all at once.

## Let somebody else write the ADR

Lesson 5 introduced the architecture decision record, with its title, status, context, decision and
consequences. In her first two months Renata wrote all nine of Carreto's new ones herself, because
she wrote quickly and knew what a good one looked like. It was the wrong economy. **Writing an ADR
is where a developer learns to state a context, name the options that lost and say what a decision
costs**, and Renata was keeping that practice for herself.

From the third month, the person closest to a decision writes its record, and Renata reviews it as
she would a design: problem first, consequences next, a label on every comment. Over the following
ten months Carreto accepted 31 more ADRs. Renata wrote 5 of them, and 14 different engineers wrote
the other 26. The early drafts were weaker than hers would have been. They improved quickly, and by
the end of the year a draft from Matching needed fewer comments than Renata's own first ones had
needed from Kátia.

Two habits made it work.

- **She resisted editing.** A comment saying "the consequences list only benefits; what does this
  cost the Driver team?" teaches. Rewriting the section does not, and it tells the author that their
  name on the record is decoration.
- **She left the decision where the advice process puts it** (lesson 3), with the author. Writing
  up somebody else's decision is clerical work. Writing up your own is design.

## Pair on design

Pair programming has a design equivalent, and it works for the same reason: two people thinking
aloud catch each other's assumptions while there is still nothing to throw away. Renata pairs on
design with one developer at a time, for an hour or two, at a whiteboard or in a shared diagram.

**The less experienced person holds the pen.** If Renata draws, the developer watches her think and
learns what her diagrams look like. If the developer draws and Renata asks, the developer does the
thinking and Renata sees exactly where it stops. When Diego Araújo, the tech lead of the Driver app,
had to design offline support for drivers in areas with no signal, Renata spent two sessions with
him at the whiteboard and drew nothing. She asked what the app should do when a driver confirms a
delivery with no signal, what happens if the same confirmation arrives twice when the signal comes
back, and how Tracking would learn the real time of delivery. Diego's design kept a queue of events
on the phone, each with the time it happened, and a key on each event so that a repeat changes
nothing. It was his design, and he defended it at the forum the following week.

Pairing also gives an architect something no document does: a direct view of how each developer
reasons, which is what a plan for their growth has to be built on.

## Hand a decision over in steps

Neither practice is all or nothing. Renata hands a kind of decision to somebody in four steps, and
she names the step out loud so that both of them know where they stand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A staircase of four steps rising from left to right, with an arrow above: the decision moves to the developer. Step one: I decide, and explain why. Step two: we decide together. Step three: you decide, I review before it is final. Step four: you decide, and tell me after. Under step two: Kátia, for contracts with Payments. Under step three: Ícaro, for payment designs. Under step four: Kátia, inside Matching.\"><defs><marker id=\"handover-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 30 L560 30\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#handover-ah)\"></path><text x=\"30\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the decision moves to the developer</text><rect x=\"24\" y=\"196\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"104\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">step 1</text><text x=\"104\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">I decide,</text><text x=\"104\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and explain why</text><rect x=\"196\" y=\"150\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">step 2</text><text x=\"276\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">We decide</text><text x=\"276\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">together</text><text x=\"276\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Kátia: contracts with Payments</text><rect x=\"368\" y=\"104\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">step 3</text><text x=\"448\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">You decide, I review</text><text x=\"448\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">before it is final</text><text x=\"448\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Ícaro: payment designs</text><rect x=\"540\" y=\"58\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">step 4</text><text x=\"620\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">You decide,</text><text x=\"620\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and tell me after</text><text x=\"620\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Kátia: inside Matching</text></svg>", "caption": "Handing a kind of decision over in steps. The step belongs to the kind of decision, not to the person: Kátia stands on two different steps at once."}
```

1. **I decide, and explain why.** The developer watches the reasoning.
2. **We decide together.** The developer brings options and argues for them; Renata still holds the
   decision.
3. **You decide, and I review before it is final.** The method of the previous section, labels
   included.
4. **You decide, and tell me afterwards.** Renata learns of it from the ADR, like everybody else.

**The steps belong to a kind of decision, not to a person.** Kátia was at step 4 for the internal
design of Matching from Renata's first week, and at step 2 for anything that changed a contract with
Payments, because a mistake there lands on another team. Ícaro was at step 2 for payment designs
until the retry document, which moved him to step 3. Saying the step aloud prevents the two quiet
failures of delegation: the architect who hands over a decision and then overrules it, and the
developer who was handed one and never noticed.

## Katas: practice where nothing is at stake

The trouble with learning design on real work is that real work arrives rarely and carries real
risk. A developer might design two significant things in a year, each with production behind it.
Musicians and athletes solve the same problem with practice that is not the performance.
**Architectural katas, devised by Ted Neward, are that practice for design.**

A kata is a short brief for an invented system: a few paragraphs about the users and the business,
and a handful of requirements and constraints. Small groups get the same brief and a fixed time to
produce an architecture. Then each group presents, the others question it, and the discussion is
about reasoning: what each group chose, what it gave up and why. There is no correct answer to find,
and that is deliberate.

Carreto runs one a month at the architecture forum from lesson 10, in ninety minutes: fifteen to
read the brief and ask questions, forty-five to design in groups of three or four, and thirty to
present and question. Renata writes the briefs, and she sets them in businesses other than freight
so that nobody can lean on what they know of Carreto's systems. One described a library that lends
tools instead of books, with members, three branches, a waiting list and fines. Another described a
school canteen that takes orders from parents' phones and has to close at 10:30.

Two rules keep the katas worth the time.

- **Mix the groups.** A junior developer from Payments, a senior engineer from Platform and a tech
  lead from Driver disagree in ways that three people from one team never will.
- **Question the trade-offs, not the boxes.** "Why is the waiting list a separate service?" is a
  good question. "I would have used Postgres" is not, unless it changes a trade-off.

## Is it working?

**The measure is how many sound decisions get made without the architect**, and it can be watched,
roughly. Renata keeps three columns in a spreadsheet: who wrote each ADR, how many review comments
were blocking, and how many design questions reached her that a team could have answered alone.
Over the ten months after the change, the share of ADRs written by somebody else was about five in
six, and blocking comments per review fell from about three to fewer than one.

The conversations behind those numbers are a craft of their own, and another course teaches it.
Mentoring and development plans are lesson 10 of `architect-communication`, code review as a
teaching tool is its lesson 11, and pair and mob programming are its lesson 12.
