---
title: Lighter methods for an afternoon
version: 1
---

**Most reviews do not need a full ATAM, and a light review held is worth more than a heavy one
postponed.** Two lighter methods carry ATAM's core ideas, scenarios, risks and trade-offs, into
something a team can run in an afternoon.

## Risk storming

**Risk storming**, described by Simon Brown, is a collaborative way to find risks on the diagrams the
team already has:

1. **Draw the architecture** at the level that matters, usually lesson 3's container diagram, large,
   on a wall or a shared board.
2. **Everybody identifies risks alone**, in silence, for ten minutes, each written on a sticky note
   with its likelihood and impact, low, medium or high.
3. **Everybody places their notes** on the part of the diagram the risk is about.
4. **The group looks at where the notes cluster** and discusses the clusters, starting with the
   highest likelihood times impact.
5. **The group decides what to do** about the top risks: mitigate, accept, or investigate further.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l13-risk-storm\" aria-label=\"A risk-storming board: Carcará's containers drawn large, with sticky notes placed by reviewers. Notes are coloured by likelihood times impact. One note sits on the ticketing API, two on the booking database, and a cluster of four on the boarding sync service, all reading two phones, one ticket. Two notes sit on the link between a station and the cloud.\"><defs><marker id=\"l13-risk-storm-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"45.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Station counter</text><text x=\"110.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"280.0\" y=\"45.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing API</text><text x=\"360.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"530.0\" y=\"45.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Booking DB</text><text x=\"610.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><rect x=\"280.0\" y=\"185.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Boarding sync</text><text x=\"360.0\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"30.0\" y=\"185.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Boarding app</text><text x=\"110.0\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Android]</text><path d=\"M190.0 70.0 L280.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><path d=\"M440.0 70.0 L530.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><path d=\"M190.0 210.0 L280.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><path d=\"M360.0 185.0 L360.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><rect x=\"200.0\" y=\"16.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"233.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">link down</text><rect x=\"200.0\" y=\"100.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"233.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">link down</text><rect x=\"420.0\" y=\"112.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">pool size</text><rect x=\"570.0\" y=\"112.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"603.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">failover?</text><rect x=\"640.0\" y=\"112.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"673.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">disk full</text><rect x=\"450.0\" y=\"170.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"483.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 phones</text><rect x=\"520.0\" y=\"170.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 phones</text><rect x=\"450.0\" y=\"248.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"483.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 phones</text><rect x=\"520.0\" y=\"248.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 phones</text><text x=\"560.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">four notes, written alone, on one service</text></svg>", "caption": "The cluster is the finding. Four people wrote the same risk without talking to each other, which is why the silent step comes before the discussion."}
```

The silent individual step is the important one. It stops the most senior voice from setting the
agenda and collects risks that people would not raise in open discussion. At Carcará, the cluster
around the boarding sync service surprised the architects: four people, independently, had written
that nobody knew what happened when two phones uploaded scans for the same ticket.

## A decision-centred review

A second light method reviews **the decisions** rather than the diagrams, and it fits teams that keep
lesson 5's decision log:

1. Pick the five to ten **records that matter most** for the scenarios at stake.
2. For each, ask the **forces question**: are the forces in its context still true? Lesson 5 put
   numbers and dates in contexts for exactly this.
3. Ask the **consequences question**: did the consequences it predicted come true, the good and the
   bad?
4. Mark each record **still sound**, **to revisit** or **to supersede**.

Carcará ran it on the seat-hold record, ADR-0009: the forces still held, the predicted CPU drop had
happened, and the predicted negative, holds lost on a Redis restart, had happened twice. Still sound,
with one new action: restarts of Redis move to the quiet hours.

## Choosing

| situation | method |
| --- | --- |
| a high-stakes, hard-to-reverse commitment, with time | ATAM, or a shortened version of it |
| before a known stress, with a container diagram | risk storming |
| a mature system with a decision log | decision-centred review |
| one new design document | `architecture-role` lesson 11's three passes |
