---
title: The shape
version: 1
---

Every runbook has the same headings in the same order, whatever the symptom. **The fixed shape is
the point.** At three in the morning you find the section you need without reading the ones
before it, and when a runbook is missing a section, the gap is visible on the page instead of
discovered during the incident.

A header, then seven sections:

| section | what it holds |
|---|---|
| header | what the runbook is for, which servers it applies to, its owner, and the date it was last rehearsed |
| **Symptom** | how you arrive here: the alert's exact text, or what users report |
| **Impact** | what is broken now and what breaks next if nothing is done, so you know how fast to move |
| **Check** | commands that only read, each with what its answer means |
| **Act** | for each finding in Check, the command that deals with it |
| **Verify** | how to tell each act worked, and what you will see if it did not |
| **Roll back** | how to undo each act, or a plain statement that it cannot be undone |
| **Escalate** | whom to call, at what threshold or after how long, and what to hand them |

Four rules make those headings work.

**Check only reads.** Every command under it is safe to run by anybody, at any time, as often as
they like — `df`, `du`, a `SELECT`. That way the person following the page never has to decide
whether a step is safe while they are still finding out what is wrong.

**Every act names the finding that leads to it.** "If a slot is inactive and retaining WAL" is an
act. "Free up space" is a wish. The condition is what stops somebody running the right command
for the wrong problem.

**Every act has its verify and its roll back, written before they are needed.** If an act cannot
be undone, the runbook says so in those words, next to the act, with what is lost. That sentence
is what makes a tired person stop and ask first.

**Escalation has a number in it.** "Call the second line if it gets worse" leaves the decision to
the person least able to make it. "Above 95%, or still climbing thirty minutes after the act" does
not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 244\" role=\"img\" aria-label=\"The runbook as a loop. Symptom leads to Check, which only reads; Check leads to Act, where each act names the finding that leads to it; Act leads to Verify, one per act; a verify that passes ends at Resolved. A verify that fails goes back to Check with one more thing known, or, if the act made things worse, to Roll back. Under every step runs Escalate: from any step, at the number the page gives.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Symptom</text><rect x=\"160\" y=\"70\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Check</text><text x=\"225.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">only reads</text><rect x=\"330\" y=\"70\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Act</text><text x=\"395.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">names its finding</text><rect x=\"500\" y=\"70\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Verify</text><text x=\"560.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one per act</text><rect x=\"660\" y=\"70\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"705.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Resolved</text><line x1=\"130\" y1=\"94.0\" x2=\"157\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"290\" y1=\"94.0\" x2=\"327\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"460\" y1=\"94.0\" x2=\"497\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"620\" y1=\"94.0\" x2=\"657\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><path d=\"M560 70 C560 22 225 22 225 66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><text x=\"392\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">not fixed: back to Check, knowing more</text><rect x=\"430\" y=\"150\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Roll back</text><line x1=\"545\" y1=\"118\" x2=\"512\" y2=\"147\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"552\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">worse</text><rect x=\"10\" y=\"204\" width=\"740\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"380\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Escalate: from any step, at the number the page gives</text></svg>", "caption": "The shape of a runbook is a loop, with a way out at every step."}
```

The order is a loop more than a list. A verify that fails sends you back to Check with one more
thing known, or to Roll back if the act made it worse. Escalation sits under every step, because
the moment to call somebody is whenever the page has run out, wherever on the page that happens.
