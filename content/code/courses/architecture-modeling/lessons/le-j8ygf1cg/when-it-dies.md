---
title: When a document dies, and how to let it
version: 1
---

**Every page eventually stops being true, and the only question is whether its death is visible.** A
page that dies silently goes on being read and believed; a page that dies visibly tells its reader
where to go instead. Planning the second is part of writing the page.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l11-page-life\" aria-label=\"The life of a description page as a state machine. It starts as Draft, becomes Current when reviewed, and stays Current through a loop labelled verified by its owner on its cadence. From Current, three exits: Deleted, when nobody needs it; Archived, with a banner, when it explains a past state; Tombstone, a single line pointing to its replacement, when many pages link to it. A dashed transition from Current to itself labelled nobody decided leads to the state to avoid: dead but unmarked.\"><defs><marker id=\"l11-page-life-am-fill-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-page-life-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><circle cx=\"30.0\" cy=\"110.0\" r=\"7\" fill=\"var(--paper)\"></circle><path d=\"M37.0 110.0 L68.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><rect x=\"70.0\" y=\"90.0\" width=\"100.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Draft</text><path d=\"M170.0 110.0 L248.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"209.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">reviewed</text><rect x=\"250.0\" y=\"88.0\" width=\"120.0\" height=\"44.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Current</text><path d=\"M280 88 C280 48, 340 48, 340 88\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"310.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">verified on its cadence</text><rect x=\"520.0\" y=\"20.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Deleted</text><path d=\"M370.0 99.5 L518.0 40.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"448.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">nobody needs it</text><rect x=\"520.0\" y=\"90.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Archived</text><path d=\"M370.0 110.0 L518.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"448.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">explains the past</text><rect x=\"520.0\" y=\"160.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Tombstone</text><path d=\"M370.0 120.5 L518.0 180.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"448.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">many links point here</text><rect x=\"230.0\" y=\"205.0\" width=\"160.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Dead, unmarked</text><path d=\"M310.0 132.0 L310.0 203.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-page-life-am-fill-amber)\"></path><text x=\"318.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">nobody decided</text></svg>", "caption": "Three deliberate ends, and one that happens by default. The default is the one a reader believes."}
```

## Three ways to end a page

| | what happens | when it fits |
| --- | --- | --- |
| **delete** | the page is removed; history keeps it in version control | it was wrong, superseded and nobody links to it |
| **archive** | it moves to an archive folder with a banner: *archived on 2025-11-03, no longer maintained* | it explains a past state somebody may need to understand, such as the station back office before it was retired |
| **tombstone** | the page is emptied except for one line saying what replaced it and where | it is linked from many places, and a deletion would leave broken links |

What is never acceptable is the fourth, default option: **leaving a dead page in place, unmarked**,
because nobody decided. That is the state 109 of Carcará's 140 pages were in.

## Deciding which pages die

Carcará went through the 140 pages in four sessions of an hour, with the owner of each area in the
room, asking three questions of each page:

1. **Does anybody need it?** If nobody could name a reader, it was deleted.
2. **Is it true?** If not, and the owner would not fix it this month, it was archived or deleted.
3. **Is it the only copy of something?** If the page held the only description of, say, the nightly
   Frota export, it was kept and fixed first, whatever its state.

Sixty-four survived. Thirty-one were archived, mostly descriptions of retired systems that explain
why the current ones look as they do. Forty-five were deleted, and **nobody has asked for one of them
since**.

## Records are different

Decision records, postmortems and meeting notes are **records**: true as of a date, never updated,
never tombstoned. They do not die; they age, and their status says so. A superseded decision
record stays exactly where it is, which is what lesson 5 relied on. The deletion rules in this section
apply to **descriptions**, the pages that claim to say how things are now.

## Ownership when people leave

The commonest cause of death is not change but departure: the owner leaves, the page stays, nobody
inherits it. Carcará's rule is that **a page is owned by a team, with a named person as contact**,
and when the person leaves, their pages appear on the team's list of things to reassign in the
same week as their laptop. The documentation outlives the project only if it outlives the people,
and that is a matter of who is written at the top.
