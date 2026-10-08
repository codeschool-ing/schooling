---
title: Three documents, and which one a decision needs
version: 1
---

**A document that asks for a decision should be as large as the decision and no larger.** A
twelve-page design document for a change one team can undo in an afternoon wastes everybody's
reading time. A chat message for a change that rewires how five teams store data skips the people
who will live with it.

Marola uses three shapes, and most companies that write things down end up with something close to
them under other names.

| | one-pager | technical proposal | RFC |
|---|---|---|---|
| decides | one change, by a known person or small group | a design, with alternatives compared | a rule or a change that affects many teams |
| length | one page, read in five minutes | three to ten pages | whatever the subject needs, plus the comments |
| who comments | the people who approve it | the reviewers named at the top | anybody affected, inside a fixed window |
| ends with | a yes, a no or a date | an approved design | an accepted or rejected record |

The axes that decide between them are **how many teams the change touches** and **how hard it is to
reverse**. A change one team can reverse cheaply needs a message or a one-pager. A change that is
hard to undo, or that changes what other teams must do, needs a written proposal, and when the
"other teams" are most of the company, an open RFC.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A chart with two axes: how many teams a change touches, from one to many, and how hard it is to undo, from easy to harder. One team and easy to undo: a message. A decider, a cost and a date: a one-pager. Harder to undo: a technical proposal, with alternatives compared and reviewers named. Many teams: an RFC, where anybody affected may comment for a fixed time.\"><defs><marker id=\"matrix-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 290 L690 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#matrix-ah)\"></path><path d=\"M90 290 L90 20\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#matrix-ah)\"></path><text x=\"390\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">teams the change touches: one → many</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">harder</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to undo</text><text x=\"20\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">easy</text><rect x=\"110\" y=\"200\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a message</text><text x=\"200.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one team, cheap to undo</text><rect x=\"310\" y=\"200\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a one-pager</text><text x=\"400.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a decider, a cost, a date</text><rect x=\"310\" y=\"40\" width=\"180\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a technical proposal</text><text x=\"400.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alternatives compared,</text><rect x=\"510\" y=\"40\" width=\"170\" height=\"230\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">an RFC</text><text x=\"595.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">anybody affected may</text><text x=\"400\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reviewers named</text><text x=\"595\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">comment, for a fixed time</text></svg>", "caption": "The size of the document follows the size of the decision: how many teams it touches, and how hard it would be to take back."}
```

## Why write at all

The objection is always the same: "We could settle this in a meeting." Sometimes that is true. A
written document beats a meeting in three ways that matter for decisions that last:

- **It forces the thinking to finish.** A meeting tolerates "we will figure out the rollback later".
  A page with an empty section called *Rollback* does not.
- **It reaches the people who were not in the room**: the team in another time zone, the engineer
  who joins next year and wonders why the route planner reads from a replica.
- **It is read before anybody argues.** Amazon has run senior meetings this way since Jeff Bezos
  banned slide presentations from them in 2004: a narrative memo of up to six pages is handed out at
  the start and read in silence by everybody, before discussion starts. Whatever one thinks of the
  ritual, it removes the meeting where half the room is reading the document for the first time
  while the author presents it.

## The cost of the wrong size

Too small is the common failure in engineering teams: a decision made in a chat thread, agreed by
whoever was online, discovered by everybody else when it breaks something of theirs. **The test is
who will be surprised.** If somebody outside the conversation will be surprised by the outcome, the
decision needed a document they could have read.

Too large is the common failure of the people who have just discovered design documents. Every
change acquires a template with fourteen headings, most of them answered "N/A", and teams start
avoiding the process by keeping changes below the size that triggers it. The point of the shapes is
to fit the decision, and the next three sections take them one at a time.
