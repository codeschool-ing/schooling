---
title: One roadmap, two authors
version: 1
---

Until this year Coreto had two roadmaps. Júlia Sato's product roadmap went to the board and the
sales team. Engineering kept a technical roadmap in a different document, which product had seen
once. **Both assumed the same 52 engineers**, and each looked achievable on its own. Together they
asked for far more than the company had, and nobody could see it, because nobody read both.

## Why two roadmaps fail quietly

A separate technical roadmap feels like progress: engineering's work is written down and has a
place. The trouble is what happens next. Product plans against the whole team, because its roadmap
does not mention anything else. Engineering plans its investment against the same team. The
conflict surfaces sprint by sprint as one item-by-item argument after another, which the previous
section showed engineering losing.

There is also a reading problem. Lesson 2 separated a roadmap from a strategy: the roadmap says what
and in what order. A roadmap that leaves out half the work being done answers that badly, and a
board reading only the product half concludes that engineering delivers less than it does.

## One document, two lanes

The fix is a single roadmap with two authors. **Júlia writes the product themes and Davi writes
the engineering themes**, in the same document, in the same three columns.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 736 344\" role=\"img\" aria-label=\"Coreto’s roadmap as a grid of three columns, Now, Next and Later, and two lanes. Product themes, written by Júlia: now, Pix in instalments and festival seat maps discovery; next, building festival seat maps; later, partner API. Engineering themes, written by Davi: now, holds without row locks, the Reservations team’s whole capacity, and the on-sale load test; next, a load-test gate replacing the freeze, and moving search to the hosted service; later, revisiting the monolith’s split and the front-end framework. An arrow runs from holds without row locks in the engineering lane to building festival seat maps in the product lane’s next column.\"><defs><marker id=\"road-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"214.0\" y=\"32\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Now</text><text x=\"416.0\" y=\"32\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Next</text><text x=\"618.0\" y=\"32\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Later</text><text x=\"60\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><text x=\"60\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">themes</text><text x=\"60\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Júlia</text><path d=\"M10 190 L726 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"60\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Engineering</text><text x=\"60\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">themes</text><text x=\"60\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Davi</text><rect x=\"122\" y=\"58\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"89\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pix in instalments</text><rect x=\"122\" y=\"120\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Festival seat maps:</text><text x=\"214.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">discovery</text><rect x=\"324\" y=\"58\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Festival seat maps:</text><text x=\"416.0\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the build</text><rect x=\"526\" y=\"58\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"89\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Partner API</text><rect x=\"122\" y=\"206\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Holds without row locks</text><text x=\"214.0\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Reservations: whole team</text><rect x=\"122\" y=\"268\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"299\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">On-sale load test</text><rect x=\"324\" y=\"206\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Load-test gate</text><text x=\"416.0\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">replaces the freeze</text><rect x=\"324\" y=\"268\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Move search to the</text><text x=\"416.0\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">hosted service</text><rect x=\"526\" y=\"206\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Revisit splitting</text><text x=\"618.0\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the monolith</text><rect x=\"526\" y=\"268\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"299\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Front-end framework</text><path d=\"M308 232 C320 232, 310 84, 321 84\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#road-ah)\"></path></svg>", "caption": "One roadmap, two lanes, three columns and no dates. The arrow across the lanes is the reason festival seat maps sit in next: they need the hold path that the engineering lane is fixing now."}
```

Three choices shape it.

**Themes, not features.** "Festival organisers can sell reserved areas" is a theme. "A seat map
component for festivals" is a feature, one possible answer to it. A theme states a problem worth
solving and leaves discovery free to find the solution; the previous section of this lesson showed
why that freedom matters. Engineering themes follow the same rule: "Seat holds survive an on-sale"
is a theme, and holding seats without row locks is the answer ADR-0006 chose.

**Now, next, later, and no dates.** Now is what the teams are working on this quarter. Next is
what they expect to start once something in now finishes. Later is real intent with no commitment.
**The columns are an order, not a schedule.** When somebody needs a date for an item, the honest answer
is a range with a confidence attached, and `delivery-metrics` lesson 11 covers how to produce one
and how to have that conversation. This lesson leaves it there.

**Arrows across the lanes.** The arrow from "Holds without row locks" to "Festival seat maps" is the
most useful line in the document. It tells a reader on the product side why festival maps sit in
next and not in now, and it tells them in a form that does not need an engineer to explain. Before,
the same dependency lived in Mateus's head and would have surfaced in a missed date.

## The proportions follow the split

The engineering lane is not free to grow. Its themes have to fit inside the share of capacity agreed
in the previous section, and the product lane fills the rest. If Davi's lane holds more than the
share can carry, the roadmap shows it at a glance, and the conversation happens at the quarterly
review instead of halfway through a sprint.

The exception is visible too. The Reservations team's two quarters on the hold path sit in the
engineering lane marked as a whole team's capacity, because the strategy put them outside the split. A reader who knows
the agreement can check the drawing against it.

## How two authors work together

Two authors need rules for disagreement, or the roadmap goes back to being two documents in one
file. Coreto's are short.

1. Each author owns their lane. Júlia does not reorder engineering themes, and Davi does not reorder
   product themes.
2. A theme moves between columns only when both agree, because a move in one lane changes what the
   other can do.
3. An arrow across the lanes is added by whoever finds the dependency, and removed only by the
   author of the theme it points from.
4. When they cannot agree, the disagreement goes to Helena Prates and the CEO together, with each
   side's case in writing.

They present it together at the quarterly review, Júlia first. **The board sees one roadmap and
two people answering for it**, and when somebody asks why festival maps are not in now, the answer
comes from the product side, pointing at an engineering theme.

## What changes for engineering

Engineering gives something up in this arrangement. A technical roadmap it wrote alone was a place
where every investment it wanted could be listed. In the shared document every engineering theme
competes for a place in a lane of fixed width, and product reads the reasons. Some themes that sat
on the old technical roadmap for a year without moving were dropped in the first review, because
nobody could state a problem they solved.

What it gets back is larger. Engineering work becomes part of the plan the company commits to,
instead of a list that loses every sprint. And when the hold path is fixed and festival maps ship,
the roadmap shows that one made the other possible. Lesson 19 builds on this: saying no to a
request is easier when the roadmap already shows what the yes would displace.
