---
title: The PowerPoint architect
version: 1
---

**The PowerPoint architect describes a system that exists only on slides.** The diagrams are clean,
the target state is persuasive, and the teams build something else, not out of defiance but because
the slides answered questions nobody in the code was asking. Lesson 2 drew the line this
antipattern crosses: a diagram is a view of the architecture, and the architecture is whatever
runs. An architect who works only on the view ends up the author of a document that the system does
not match.

Every antipattern in this lesson starts as a reasonable habit taken too far, and this one is no
exception. Drawing the system is part of the job (lesson 8), and so is describing where it should
go. The failure is when the drawing replaces the system as the thing the architect looks at.

This lesson describes each antipattern through a version of Renata who took the wrong turn. These
versions are invented, like Carreto itself; the real Renata of lessons 1 to 16 did not do these
things, and the point of imagining her doing them is to see how small the first step is.

## What it looks like

Picture Renata eighteen months from now, having spent most of them on a deck called *Carreto
2028*. It runs to 46 slides. Slide 12 shows the drivers' payment flow: Tracking publishes an event
when a delivery is proved, Payments subscribes, and the Shipper app reads invoices from Payments'
API. It is a good design. Meanwhile, in the code:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Two drawings side by side. On the left, slide 12 of the deck Carreto 2028: Tracking sends a delivery-proved event to Payments, and the Shipper app reads invoices from Payments through an API. On the right, the code the same week: Payments polls Tracking every 5 minutes; Payments writes invoices into the monolith database and the Shipper app reads them from there; a nightly job copies delivery proofs from Tracking into the same database. The monolith database is not on the slide.\"><defs><marker id=\"sl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M360 30 L360 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"183\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">slide 12 of Carreto 2028</text><text x=\"537\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the code, the same week</text><rect x=\"36\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"91\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"220\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Tracking</text><rect x=\"128\" y=\"200\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"183\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Payments</text><path d=\"M262 112 L210 196\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"250\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">event:</text><text x=\"250\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">delivery proved</text><path d=\"M150 198 L104 114\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"108\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">invoices API</text><rect x=\"390\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"574\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"629\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Tracking</text><rect x=\"574\" y=\"170\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"629\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Payments</text><rect x=\"390\" y=\"250\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"465\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">monolith database</text><path d=\"M629 168 L629 114\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"638\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">polls every</text><text x=\"638\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 minutes</text><path d=\"M445 112 L445 246\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"438\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads</text><path d=\"M590 212 L532 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"584\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">writes</text><path d=\"M580 112 L512 246\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#sl-ah)\"></path><text x=\"538\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nightly copy</text></svg>", "caption": "The same three services. The slide has two connections; the code has three, and two of them run through a database the slide does not draw."}
```

Three connections where the slide has two, and two of them run through a database nobody drew.
None of the three was a secret;
each was added by a team solving a problem that week, and none of those teams had a reason to open
the deck. The symptoms that give the antipattern away:

- **The diagrams are dated by the meeting, not by the code.** Nobody can say which commit slide 12
  describes, because it describes none.
- **Teams nod in the review and build something else.** Objecting to a slide costs a meeting;
  ignoring it costs nothing.
- **The architect learns about production from incidents.** She is not on call, does not read pull
  requests and has not opened the repository since the deck began.
- **Questions about today are answered with the target.** "How does Payments learn that a delivery
  was proved?" gets "in the target architecture, through an event", which is true of the deck and
  false of the system.

## Why it happens

The causes are ordinary, and that is what makes the antipattern common.

**Slides are rewarded where they are seen.** The audience of a target-architecture deck is Tomás,
Helena and Sílvio, who see a clear story and cannot check it against the code. Nobody in that room
is in a position to say "slide 12 is not how it works".

**A target is easier to draw than a path.** Drawing 2028 takes a week. Getting from today to there
means negotiating with seven teams, ordering the steps so that each one ships, and accepting that
the drawing will change on the way. The first is satisfying work and the second is most of the job.

**The architect stopped writing and reading code.** Lesson 15 called this losing calibration: the
architect who no longer feels what a design costs to build stops noticing that the design is not
being built.

**Nobody owns the drawing once it is presented.** Lesson 8 showed how a document without an owner
rots, and how the stale document that is still believed does more harm than a missing one.

## What it costs

The first cost is **decisions taken on a picture**. A new engineer, reading the deck during their
first week, builds a feature against the delivery-proved event and spends three days finding out
that it does not exist. Carreto hires about twelve engineers a year; three days each is **36 days a
year** lost to a diagram, before counting the managers who promised shippers a feature because the
slide made it look one step away.

The second cost is slower and worse: **the architect's credibility**. Once a team discovers that
the slides are not the system, it discounts everything the architect says, including the parts that
were right. Lesson 3 described authority as earned through track record; the PowerPoint architect
spends it on a document and gets nothing back.

## The alternative

The alternative is not to stop drawing. It is to tie the drawing to the system at both ends:

- **Draw what exists first, and date it.** The current-state view lives next to the code, is
  reviewed in pull requests like the code, and says which version it describes (lesson 8). A target
  drawn beside an honest current state shows its own distance from reality.
- **Make the target a sequence of steps, each one shippable.** "Payments subscribes to the
  delivery-proved event" becomes a first step owned by the Tracking team with a date on it. **A
  target with no first step is a wish.**
- **Let the build check the drawing where it can.** The fitness function from lesson 9 fails when
  Payments imports Matching's internals; it is a diagram that cannot drift, because it breaks the
  build the day the code disagrees with it.
- **Stay in the code** (lesson 15), so that the drawing is made by somebody who would notice when it
  stops being true.

One question tells the two kinds of architect apart: **can the person who drew this arrow point to
the code where it lives?** The real Renata can. The version with the deck could only point to the
slide.
