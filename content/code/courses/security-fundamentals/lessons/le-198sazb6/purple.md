---
title: Purple: the two in one room
version: 1
---

The classic arrangement keeps red and blue apart. The red team works for weeks, writes a report, and
the blue team reads it afterwards: "on day three we reached the database and nobody noticed". By then
the logs from day three have often been rotated away, the people who might have noticed cannot
remember what they saw, and the lesson arrives too late to be tested.

**Purple teaming** puts the two colours in the same room, or the same call, and changes the rhythm.
The red side runs one technique. The blue side immediately asks whether it was seen: in which log,
by which rule, and how long it took. If it was not seen, they work out why, change something and run
the technique again. The cycle repeats until the technique is detected, or until everybody agrees why
it cannot be.

```schooling-figure
{"svg": "<svg id=\"sf-purple-loop\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The purple loop. Red runs one technique. Blue asks whether it was seen: in which log, by which rule, how fast. If it was not seen, both change something: a log, a rule, a setting. Then red runs the same technique again. The loop ends with a detection proved to work.\"><defs><marker id=\"sf-purple-loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sf-purple-loop-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-purple-loop-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">red runs a technique</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">blue: was it seen?</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a detection that works</text><rect x=\"270\" y=\"140\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">change a log, a rule</text><path d=\"M200 55 L270 55\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-wire)\"></path><path d=\"M450 55 L520 55\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-phosphor)\"></path><text x=\"485\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><path d=\"M360 80 L360 140\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-amber)\"></path><text x=\"370\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><path d=\"M270 165 L110 165 L110 80\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-wire)\"></path><text x=\"190\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">run it again</text></svg>", "caption": "One technique at a time, until the defence is proved to see it."}
```

The result is not a list of holes but a **detection that has been proved to work**, which is a
different and more durable kind of output. A firewall rule tested by its author says what the author
thought of; a detection tested by somebody actively trying to get past it says what an attacker
would run into.

### What purple is not

Purple is a way of working, not a third team. Most organisations that "have a purple team" have red
and blue people who agreed to cooperate, sometimes with a facilitator in the middle. That facilitator
role is sometimes called the **white team**: the referees who write the rules, keep the exercise
inside them and decide what counts.

### Why it matters at a small scale

A nine-person shop has no red team and no SOC. It still has the purple idea, and it is the cheapest
security practice in this course: **whenever you add a control, try to get past it, and look at what
your logs recorded when you did.** ana does exactly that in the next section, with six wrong passwords
and the portal's log.
