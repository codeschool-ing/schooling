---
title: Choosing a technology, and how much care the choice deserves
version: 1
---

The common picture of a technology decision is a contest. Somebody lists the candidates, reads the
benchmarks, counts the stars on each repository, and the best tool wins. **There is no best tool,
only a tool that fits a particular set of quality attributes, a particular team and a particular
cost of getting out again.** Lesson 2 made the point that a technology is not an architecture; this
section is about the choices that remain once the architecture has said what the system needs.

It is also about the other half of the job, which is easier to forget. **An architect is
responsible for how much care each decision gets**, and spending a week on a choice that could be
undone in an afternoon is as much a failure as deciding in an afternoon something that will take a
year to undo.

## Six questions to ask of every candidate

At Carreto the Tracking team has to decide where to keep GPS positions. At the busiest hour of the
week about 3,000 trucks are on the road, each reporting its position every 30 seconds. That is
3,000 / 30 = 100 positions a second, or 8,640,000 a day, and the positions are kept for a year
because a shipper may dispute a delivery, and the route the truck took is the evidence.

Three candidates came up in the team's first conversation: a dedicated time-series database that
one engineer had used at a previous job, the PostgreSQL the team already runs with the positions
table split by month, and a managed time-series service from the cloud provider. Renata did not
pick one. She asked the six questions she asks of any candidate, and the team answered them:

| question | what it asks | Tracking's answer, in short |
|---|---|---|
| **fit** | does it serve the quality attributes this system needs? | all three handle 100 writes a second; the year of history and the dispute queries are the test |
| **skill** | can this team build, run and debug it at three in the morning? | the team knows PostgreSQL well; one person knows the dedicated database |
| **ecosystem** | is it mature, documented, supported, and can we hire for it? | PostgreSQL wins easily; the managed service is tied to one provider's tools |
| **licence** | what may we do with it, and can that change? | check the licence of the current version, not of the one in the blog post |
| **cost** | what does it cost to run, including the people? | a second database engine means a second thing on call |
| **exit** | what would it cost to leave in three years? | high for the managed service, whose query language is its own |

**Fit comes first and decides less than people expect.** At Tracking's volume, all three candidates
fit: 100 writes a second is a modest load for any of them. When fit does not separate the options,
the decision is made by the other five questions, and those are about the team and the company
rather than about the tool.

**Skill is the question most often skipped**, because it sounds like a confession. It is a
quality attribute in disguise: a database nobody on the team can debug is a database whose
availability depends on one person's holidays. The engineer who knew the dedicated time-series
database was enthusiastic and right about its strengths, and was also the only person on a team of
six who could operate it.

**Licence deserves a sentence of its own.** Several widely used databases have moved from open
source licences to more restrictive ones in recent years, MongoDB in 2018 and Elasticsearch in
2021 among them, which changed what cloud providers may offer and, for some companies, what they
may build. The licence to read is the one on the version you would install, and the question to
ask is what happens to you if it changes again.

**Exit is the question that turns a technology decision into an architectural one.** A tool that
is cheap to replace can be chosen quickly and corrected later. A tool whose data format, query
language or API spreads through the code is a commitment, and the time to price the way out is
before the way in.

Tracking chose PostgreSQL, partitioned by month, with the decision written down and a note to look
again if the fleet grows past ten times its current size. Nobody thought it the most interesting
option. It was the one the team could run, at a load all three could carry, with the cheapest
exit.

## One-way doors and two-way doors

Jeff Bezos, in Amazon's 2015 letter to shareholders, split decisions into two types. Some are
**one-way doors**: consequential and nearly irreversible, so that once you walk through you cannot
come back. Most are **two-way doors**: if the choice turns out badly, you walk back through and try
something else. His point was that organisations tend to use the heavy process suited to the first
kind for both, and become slow; the opposite mistake, treating a one-way door as a two-way one, is
rarer and more expensive.

For an architect, the useful version adds a second axis. **How hard a decision is to reverse
matters, and so does how far its consequences reach**: one team's code, several teams, or a party
outside the company whose systems you do not control.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Two axes. Across, how far a decision reaches, from one team to several teams or an outside party. Up, the cost of reversing it, from cheap to expensive. Four quadrants: bottom left, the team decides and moves fast, with Pricing's logging library; top left, the team decides slowly and writes it down, with Tracking's position store; bottom right, agree the contract then move, with a new optional field in an event; top right, a one-way door that needs the architect and a decision record, with how Payments learns of proofs and the API that shippers' systems call.\"><defs><marker id=\"door-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 330 L696 330\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></path><path d=\"M80 330 L80 30\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></path><path d=\"M385 36 L385 326\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><path d=\"M84 180 L690 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"88\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cost to reverse</text><text x=\"72\" y=\"50\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">high</text><text x=\"72\" y=\"320\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">low</text><text x=\"92\" y=\"350\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one team</text><text x=\"690\" y=\"350\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">several teams, or outside</text><text x=\"690\" y=\"372\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">how far it reaches</text><text x=\"94\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">team decides, slowly, writes it down</text><text x=\"399\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">one-way door: architect and an ADR</text><text x=\"94\" y=\"316\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">team decides, moves fast</text><text x=\"399\" y=\"316\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">agree the contract, then move</text><circle cx=\"180\" cy=\"110\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"192\" y=\"114\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking's position store</text><circle cx=\"180\" cy=\"258\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"192\" y=\"262\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pricing's logging library</text><circle cx=\"440\" cy=\"250\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"452\" y=\"254\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a new optional field in an event</text><circle cx=\"440\" cy=\"100\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"452\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">how Payments learns of proofs</text><circle cx=\"470\" cy=\"140\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"482\" y=\"144\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the API shippers' systems call</text></svg>", "caption": "How much care a decision deserves depends on two things at once: what it costs to undo, and how far beyond one team it reaches. Only the top right needs the architect by default."}
```

Four Carreto decisions sit in the four corners:

- **Which logging library Pricing uses** is a two-way door inside one team. If it disappoints,
  Pricing swaps it in a day. The team decides in a conversation and moves on.
- **Where Tracking keeps its positions** stays inside one team but is expensive to reverse,
  because a year of data would have to move. The team still decides, and it decides slowly: the six
  questions, a record, a review by somebody outside the team.
- **Adding an optional field to an event** reaches another team and is cheap to undo, because
  consumers that do not read the field are unaffected. The two teams agree the contract and go.
- **How Payments learns that a delivery was proved, and the API that shippers' own systems call**,
  both reach beyond one team and are expensive to reverse. The first binds two teams to a contract
  and to each other's failure behaviour; the second binds outside companies, whose integration
  projects Carreto cannot schedule. These are the one-way doors, and they are where Renata's
  attention goes by default.

The next section shows the first of those decisions written down whole.

## Making a door two-way

The best move with a one-way door is sometimes to turn it into a two-way one before walking
through. **Most of the cost of reversing a technology choice is the code that knows about it**, and
that can be contained:

- put the technology behind an interface the rest of the code owns, as Pricing did with its routing
  provider in lesson 4;
- keep data in formats other tools can read, so leaving does not start with a conversion project;
- version a public contract from its first release, so the second version can live beside it;
- run a small, real trial before the commitment, which lesson 14 calls a spike.

None of these is free, and applying all of them to every decision is the overengineering lesson 17
describes. **They are worth paying for exactly where the door would otherwise be one-way.**

## Who decides what

Placing a decision on the two axes also answers who should take it. A two-way door inside one team
is the team's, and an architect asking to be consulted on it is a bottleneck. A one-way door that
reaches several teams or the outside is one Renata takes part in, through the advice process from
lesson 3: whoever decides asks those affected and those with expertise, and writes down what was
decided and why. The writing down is the subject of the rest of this lesson.
