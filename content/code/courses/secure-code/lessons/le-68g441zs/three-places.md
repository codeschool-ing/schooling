---
title: Three places a flaw is born
version: 1
---

The usual picture of a security flaw is a clever outsider finding a crack in a finished system.
That picture puts the problem at the end, in the attacker's hands. **Most flaws are written in at
the start, by the people building the system, and they arrive in one of three places**: the
requirement, the design or the implementation. Where a flaw was born decides who can catch it and
how much the fix costs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l01-births\" aria-label=\"Three places a flaw is born, left to right in the order a feature is made. In the requirement: nobody wrote that a patient may cancel only their own booking. In the design: the staff console was designed to answer from the internet. In the implementation: the search joins the patient's text into SQL. Under each, the cheapest place to catch it: reading the requirement, a threat model, a code review or a test. An arrow along the bottom says the cost of a fix grows the later the flaw is found.\"><defs><marker id=\"l01-births-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-births-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">requirement</text><rect x=\"30\" y=\"86\" width=\"200\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"106.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">“a patient may cancel</text><text x=\"130.0\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a booking” — whose?</text><text x=\"130\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">caught cheapest by</text><rect x=\"30\" y=\"182\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reading the requirement</text><path d=\"M230 48 L260 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-births-ah-paper-dim)\"></path><rect x=\"260\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">design</text><rect x=\"260\" y=\"86\" width=\"200\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"106.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the staff console</text><text x=\"360.0\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">answers from the internet</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">caught cheapest by</text><rect x=\"260\" y=\"182\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a threat model</text><path d=\"M460 48 L490 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-births-ah-paper-dim)\"></path><rect x=\"490\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">implementation</text><rect x=\"490\" y=\"86\" width=\"200\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"106.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the search joins</text><text x=\"590.0\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">text into SQL</text><text x=\"590\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">caught cheapest by</text><rect x=\"490\" y=\"182\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a review, a test</text><path d=\"M30 256 L690 256\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l01-births-ah-amber)\"></path><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the later it is found, the more the fix costs</text></svg>", "caption": "The same portal, three flaws, born in three different places. Each is cheapest to catch where it was born."}
```

### In the requirement

A requirement is a sentence somebody agreed to. Vereda's portal has this one: *a patient can
cancel a booking online up to 24 hours before the session.* Every word in it is correct, and it
still leaves something out. It never says **whose** booking. A developer who builds exactly what the
sentence says builds a cancel button that works on any booking, and no test written from the
sentence will complain.

A requirement flaw is a missing sentence, so it cannot be found by reading the code. The code does
what it was asked. It is found by reading the requirement and asking who must **not** be able to
do this, which is a question a security-minded reviewer asks of every user story.

### In the design

A design flaw is a decision about the shape of the system. The staff console, where receptionists
manage the agenda and physiotherapists write clinical notes, was designed to answer from the
internet like the patient portal does. Each line of its code can be perfect and the console is
still one stolen password away from every clinical note at Vereda.

No review of a single file finds that, because no single file is wrong. It is found by drawing the
system and asking what can go wrong with each part, which is threat modelling.

::: track devsecops
The `threat-modeling` course, right after this one in your track, is entirely about it, and works
on this same portal.
:::

::: track *
The `threat-modeling` course is entirely about it, works on this same portal, and names this
course as the one to take first.
:::

### In the implementation

The third place is the one this course is about. The design says the patient search uses
parameterised queries. The developer, in a hurry, builds the query by joining the patient's text
into the SQL string. The requirement was right and the design was right, and **the code says
something different from both**.

Implementation flaws are the commonest of the three by a wide margin, because there is so much
more code than there are requirements or designs. They are also the cheapest to catch, because
they can be caught by the person who wrote them, before anybody else sees the code: by knowing what
the safe call looks like, and by writing a test that would fail if the unsafe one came back.

### Why the place matters

The table is the reason this lesson comes first. Each place has its own kind of evidence and its
own kind of reviewer.

| born in | looks like | caught by | fixed by |
|---|---|---|---|
| requirement | a sentence that never mentions who may not | reading the story and asking about abuse | a new sentence, and a test for it |
| design | a component in the wrong place, a trust nobody checked | a threat model of the drawing | changing the shape of the system |
| implementation | a call that is unsafe where a safe one exists | a code review, a test, a scanner | changing the line, and a test so it stays fixed |

**The later a flaw is found, the more it costs to fix**, and the cost grows fastest for the first
two. A missing sentence found in a planning meeting costs a sentence. Found in production, it costs
an incident, a data protection notice and a change to code that other code now depends on.

This course works mostly on the third row, because that is where a developer's hands are. This
lesson's own example, two sections on, is the first row: the cancel button whose requirement forgot
to say *whose*.
