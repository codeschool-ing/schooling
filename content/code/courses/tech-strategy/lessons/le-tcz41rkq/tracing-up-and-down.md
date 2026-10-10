---
title: Tracing the work up and down
version: 1
---

Four documents that each answer their own question still have to agree with each other. **Every
item in a backlog should trace up to a roadmap item, the roadmap item to an action in the strategy,
and the strategy to the vision.** Followed the other way, every action in the strategy should reach
down to work somebody is doing this sprint. The checks are cheap and they find the two failures the
previous section described: work with no reason above it, and a strategy with no work below it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Four rows, from top to bottom: vision, strategy, roadmap, backlog. One vision box spans the width. In the first column a backlog item, replay a past on-sale's traffic, points up to the roadmap line Q1 on-sale load test in place, which points up to strategy action 2, build the load test first, which points up to the vision. In the second column a backlog item points up to the roadmap line Q2 GraphQL gateway for the mobile app, and above that a dashed amber box says traces to nothing. In the third column strategy action 4, no deploys before a big on-sale, points down to the roadmap line Q3 deploy freeze automated, and below that a dashed amber box says no item in any team's backlog.\"><defs><marker id=\"trace-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"trace-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"18\" y=\"63\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Vision</text><text x=\"18\" y=\"153\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Strategy</text><text x=\"18\" y=\"243\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Roadmap</text><text x=\"18\" y=\"333\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Backlog</text><rect x=\"110\" y=\"30\" width=\"600\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"62.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the 10:00 buyer gets the same checkout as the 3 a.m. buyer</text><rect x=\"110\" y=\"120\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"143.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">action 2: build the</text><text x=\"205.0\" y=\"160.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">load test first</text><rect x=\"110\" y=\"210\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"233.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Q1: on-sale load test</text><text x=\"205.0\" y=\"250.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">in place</text><rect x=\"110\" y=\"300\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"323.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">replay a past</text><text x=\"205.0\" y=\"340.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">on-sale's traffic</text><path d=\"M205.0 298 L205.0 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M205.0 208 L205.0 180\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M205.0 118 L205.0 90\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><rect x=\"320\" y=\"120\" width=\"190\" height=\"56\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"415.0\" y=\"152.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">traces to nothing</text><rect x=\"320\" y=\"210\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"233.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Q2: GraphQL gateway</text><text x=\"415.0\" y=\"250.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">for the mobile app</text><rect x=\"320\" y=\"300\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"323.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">gateway schema</text><text x=\"415.0\" y=\"340.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">for events</text><path d=\"M415.0 298 L415.0 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M415.0 208 L415.0 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#trace-am)\"></path><rect x=\"530\" y=\"120\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"143.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">action 4: no deploys</text><text x=\"620.0\" y=\"160.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">before a big on-sale</text><rect x=\"530\" y=\"210\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"233.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Q3: deploy freeze</text><text x=\"620.0\" y=\"250.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">automated</text><rect x=\"530\" y=\"300\" width=\"180\" height=\"56\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"620.0\" y=\"323.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">no item in</text><text x=\"620.0\" y=\"340.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">any team's backlog</text><path d=\"M620.0 178 L620.0 206\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M620.0 268 L620.0 296\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#trace-am)\"></path><text x=\"205.0\" y=\"384\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">traced up to the vision</text><text x=\"415.0\" y=\"384\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">an orphan: work, no reason</text><text x=\"620.0\" y=\"384\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">decoration: a reason, no work</text></svg>", "caption": "Tracing in both directions. Most work traces from the backlog to the vision; an orphan has work and no reason above it, and a decorative action has a reason and no work below it."}
```

## Tracing up: work with no reason

Start from the backlog and ask of each item, "which roadmap line is this for?", then of each
roadmap line, "which part of the strategy is this for?". Most items answer at once. The ones that do
not are the interesting ones.

At the start of the second quarter, Davi took the roadmap lines of every team and wrote beside each
one where it traced:

| roadmap line, Q2 | team | traces to |
|---|---|---|
| remove row locks from the seat-hold path | Reservations | strategy, action 3 |
| replay a past on-sale's traffic in the load test | Platform | strategy, action 2 |
| seat maps for festival venues | Catalogue | the product roadmap |
| upgrade Rails and Ruby to supported versions | Platform | keeping the lights on |
| the payment provider's new card-tokenisation API | Payments | keeping the lights on |
| GraphQL gateway for the mobile app | Mobile | nothing |
| move Catalogue search to its own service | Catalogue | nothing |

The column has four kinds of answer, and **only the last one is a problem**.

A line can trace to the technical strategy. It can trace to the product roadmap instead, because
most of what engineering builds is product work, and that work answers to product's own strategy
rather than to this one. It can be keeping the lights on: a framework past its supported life, a
provider retiring an API on a date somebody else chose. That work is real, it is not optional, and
**it should be labelled as what it is** rather than dressed up with an invented link to the
strategy. A roadmap where every line claims to serve the strategy is a roadmap where the claims have
stopped meaning anything.

The two lines that trace to nothing are the finding. The GraphQL gateway was the Mobile team's idea
from the previous year, carried over because nobody had removed it. Moving search to its own service
was the Q4 project of the old roadmap, which had simply slid forward. **Neither was wrong as an
idea.** Each was the microservices migration arriving one service at a time, which the policy had
ruled out for the year.

An orphan has three possible outcomes, and choosing one is the point of the exercise:

- the work stops, and the people go to something that traces;
- the work turns out to serve something the strategy should have said, and the strategy is amended
  in the open, so that everybody sees the change;
- the work is reclassified honestly, as product work or as keeping the lights on, if that is what
  it really is.

What must not happen is that the orphan carries on unexamined. Two lines out of seven is a fair
share of a quarter's engineering going to work the company decided, in writing, not to do.

## Tracing down: a strategy that reaches nothing

The other direction is less obvious and finds a quieter failure. Take each action in the strategy
and follow it down: which roadmap line carries it, and which team has it in a backlog right now?

Davi did this with Coreto's four actions. The first three reached the bottom: the Reservations team
existed, the load test was in Platform's sprint, and the row locks were in the Reservations backlog.
**The fourth stopped halfway.** "No deploys to the reservation module in the 24 hours before a big
on-sale" was on the roadmap for Q3, as an automated check in the deploy pipeline. But the check
needed a calendar of the year's big on-sales that the pipeline could read, and no team had that in
its backlog. Platform assumed Reservations would supply the dates; Reservations assumed Platform
owned the pipeline and would ask. Meanwhile the freeze was enforced by a message in a chat channel,
when somebody remembered.

An action that no backlog item reaches is **decoration**: it reads as a commitment, and nothing is
happening. It is also the failure people resist naming, because the strategy document still looks
complete, and pointing at the gap feels like an accusation against whoever owns it. The trace makes
it impersonal. Either an item exists in a backlog or it does not.

## How to keep the trace without a process

None of this needs a tool. It needs one column.

- On the roadmap, a column saying which action each line serves, or which other source it answers
  to: the product roadmap, or keeping the lights on.
- In each team's tracker, a label or a link from a backlog item to its roadmap line.
- Once a quarter, when the roadmap is redrawn, a short sitting reading the column upwards for orphans
  and the strategy downwards for actions with nothing below them.

A spreadsheet in the shape of the table above is enough. **What matters is that the column exists
before anybody asks**, because a trace reconstructed under pressure in a meeting always finds a
link, however thin.

## What the trace does not tell you

A line that traces is not thereby a good line. The Reservations team could trace a badly designed
change straight to action 3 and the column would look perfect. The trace answers one question —
does this work have a reason the company agreed to? — and it is silent on whether the work is done
well, sized right or worth its cost. Lessons 5 and 13 bring the money that answers those.

Lesson 3 turns to the strategy document itself: the one page a team can carry in their heads, and
the list of what the company will not do, which is what made the two orphans above recognisable at
a glance.
