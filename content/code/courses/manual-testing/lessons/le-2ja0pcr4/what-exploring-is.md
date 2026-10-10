---
title: What exploring is
version: 1
---

Exploratory testing has a reputation it does not deserve: clicking around without a plan, what a
team does when nobody wrote test cases, impossible to repeat and impossible to report. Plenty of
unplanned clicking goes by that name, which is how it earned the reputation. **What the name means
is narrower and more disciplined: learning about the product, designing tests and running them, all
at the same time, with each result deciding the next test.**

## Scripted and exploratory

In scripted testing the three activities happen in order and usually by different people at
different times. Somebody designs the cases from the requirements, as lessons 2 to 5 did, writes
each one down with its expected result, and later somebody runs them. The design is finished before
the first run. That is its strength: a case can be run by a stranger, run again on the next build,
and counted.

In exploratory testing the design is never finished in advance. Ana tries something, reads what the
application answers, and that answer is what decides her next step. An odd message makes her try
the same action from another state; a state that accepts too much makes her look for its
neighbours. The term was coined by Cem Kaner in the 1980s, and James Bach's short definition is the
one most teams quote: **simultaneous learning, test design and test execution**.

The two are ends of one line rather than two camps. A scripted case with "try a few other values
here" written into it has moved a little towards exploring; an exploratory session that starts with
a list of questions has moved a little towards a script. Almost all real testing sits somewhere
between, and the useful decision is where on the line each part of a product should sit this week.

## Why a team does both

A script checks what somebody thought to write down. **The defects scripts miss are the ones nobody
thought to ask about**, and they are a large share of what reaches customers. Lessons 4 and 5 found
boxoffice's defects by working systematically from R4, R5 and R6; nothing in those requirements
says what a refused action's message should look like, beyond R7's "a sentence saying what is
wrong", or how a refund should behave as the evening goes on. A script written from R6 does
exactly what R6 says and stops there. An explorer keeps going.

Exploration pays most in four places:

- a feature that is new, where nobody yet knows what its cases should be;
- an area whose scripted cases all pass, but which still produces complaints;
- where the requirements are thin, and a script would only restate them;
- around a defect just found, because defects cluster, and the code that produced one was written
  by the same person, in the same week, under the same pressure.

It does not replace scripts. A session's findings are not a regression check: next week nobody can
rerun "what Ana happened to try". **What an exploratory session finds becomes cases**, defect
reports and new questions, and the cases join the suites of lesson 10.

## Exploration with a structure

The answer to "impossible to plan and report" is a structure from 2000, **session-based test
management**, described by Jonathan and James Bach. Exploration happens in **sessions**: a block of
uninterrupted time with one mission, written down before it starts, notes kept while it runs, and a
short conversation when it ends. Each session leaves a sheet behind, so a manager can count
sessions per area the way they count cases, and a tester can show where the time went.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" data-fig=\"l11-session-loop\" aria-label=\"A loop of three boxes, left to right: a charter, written first; a session of 60 to 120 minutes with notes kept; a debrief using PROOF. The debrief points to three outputs: defect reports, regression cases and new charters. An arrow runs from new charters back to the charter box, labelled the next session.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"82.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"103.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">charter</text><text x=\"90.0\" y=\"118.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a mission, written first</text><rect x=\"200.0\" y=\"82.0\" width=\"180.0\" height=\"58.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"103.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">session</text><text x=\"290.0\" y=\"118.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">60 to 120 minutes, notes kept</text><rect x=\"420.0\" y=\"82.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"103.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">debrief</text><text x=\"490.0\" y=\"118.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">PROOF, 10 to 15 minutes</text><path d=\"M160.0 111.0 L198.0 111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M380.0 111.0 L418.0 111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"574.0\" y=\"22.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">defect reports</text><path d=\"M560.0 111.0 L572.0 42.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"574.0\" y=\"86.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">regression cases</text><path d=\"M560.0 111.0 L572.0 106.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"574.0\" y=\"150.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">new charters</text><path d=\"M560.0 111.0 L572.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M633 190 L633 218 L90 218 L90 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"365.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the next session</text></svg>", "caption": "Session-based test management. Each session has one charter, and its debrief turns the notes into reports, cases and the charters of the sessions after it."}
```

The four parts are the next four sections of this lesson: the mission, called a **charter**
(section 03); the **heuristics** that suggest what to try when the charter alone does not
(section 04); a real **session** on boxoffice 1.1, with its notes (section 05); and the
**debrief** that turns the notes into decisions (section 06). Lesson 1's plan for boxoffice already
asked for one exploratory session per area; this lesson runs the first.
