---
title: What adopting open source costs
version: 1
---

"It's open source, so it's free" is said in every build-or-buy meeting, and Coreto's sheet answers
it plainly. **Adopting is the most expensive of the three options**: R$ 579,600 over three years,
R$ 129,600 more than building and R$ 146,520 more than buying. The software costs nothing. Running
it costs more than anything else on the table.

## Where the money goes

Split each option's three-year total by kind — work done once, people every year, money paid out
every year — and the three options turn out to be different animals:

| | work done once | people, three years | paid out, three years | total |
|---|---|---|---|---|
| build | R$ 144,000 | R$ 198,000 | R$ 108,000 | R$ 450,000 |
| buy | R$ 36,000 | R$ 39,600 | R$ 357,480 | R$ 433,080 |
| adopt | R$ 72,000 | R$ 273,600 | R$ 234,000 | R$ 579,600 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 225\" role=\"img\" aria-label=\"Three stacked bars, one per option, showing its three-year total split into one-off work, people every year and money paid out every year. Build: R$ 144,000, R$ 198,000 and R$ 108,000, total R$ 450,000. Buy: R$ 36,000, R$ 39,600 and R$ 357,480, total R$ 433,080. Adopt: R$ 72,000, R$ 273,600 and R$ 234,000, total R$ 579,600.\"><text x=\"100\" y=\"49\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Build</text><rect x=\"110\" y=\"30\" width=\"129.6\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"239.6\" y=\"30\" width=\"178.2\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\"></rect><rect x=\"417.8\" y=\"30\" width=\"97.2\" height=\"28\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"523\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">450,000</text><text x=\"100\" y=\"99\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Buy</text><rect x=\"110\" y=\"80\" width=\"32.4\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"142.4\" y=\"80\" width=\"35.64\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\"></rect><rect x=\"178.04\" y=\"80\" width=\"321.732\" height=\"28\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"507.772\" y=\"98\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">433,080</text><text x=\"100\" y=\"149\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Adopt</text><rect x=\"110\" y=\"130\" width=\"64.8\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"174.8\" y=\"130\" width=\"246.24\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\"></rect><rect x=\"421.04\" y=\"130\" width=\"210.6\" height=\"28\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"639.64\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">579,600</text><rect x=\"110\" y=\"196\" width=\"14\" height=\"14\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"130\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one-off work</text><rect x=\"280\" y=\"196\" width=\"14\" height=\"14\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"300\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">people, every year</text><rect x=\"470\" y=\"196\" width=\"14\" height=\"14\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"490\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">paid out, every year</text></svg>", "caption": "The same three-year totals, split by kind. Buying turns most of its cost into an invoice; adopting pays no licence and carries the largest people line of the three."}
```

**Adopt has no licence and the largest people line of the three.** Its R$ 273,600 is 30% of an
engineer and 80 hours of upgrades, every year, for three years. Buying is the mirror image: most
of its cost is an invoice, and its people line is the smallest. That difference matters beyond
the totals, because money on an invoice and hours from the team are not equally easy to find. An
invoice needs a budget line and a signature. Hours come from a team that already has a backlog,
and nobody signs for them — lesson 9 is about why that line is the one that hides.

## The three costs a free licence does not cover

**Upgrades.** An open-source engine ships new versions on its own schedule. Staying on an old one
means losing security fixes; moving to a new one means reading the release notes, testing the
queries, and sometimes rebuilding every index. Coreto's estimate is 80 hours a year, and a major
version with breaking changes can take a good part of that in one go.

**Operation.** Somebody is paged when the cluster runs out of disk in the night, and somebody restores
it from a backup that has to exist and has to have been tested. Coreto's 30% of an engineer is 528
hours a year, and it lands on whoever knows the engine best. The knowledge usually sits with one or two people, and the day they leave is a cost the sheet cannot hold.

**The licence itself can change.** An open-source licence is a decision by whoever owns the
project, and owners have changed their minds. Elastic moved Elasticsearch off the Apache 2.0
licence in January 2021. HashiCorp moved Terraform to the Business Source License in August 2023.
Redis moved off the BSD licence in March 2024. A change like these applies to new releases, and
the copies already released keep the licence they came with. Every team running them still had a
new question to answer: are the new terms acceptable for how we use it? If not, do we stay on an
old version, move to another project, or pay? **Every answer to that question costs something**, and none of it is in a sheet made the
year before.

## When adopting is the right answer

None of this makes adopting wrong. It makes it a choice with a price, and the price is worth
paying when the reason is one the other two options cannot meet:

| reason | why the other two fall short |
|---|---|
| the data may not leave your own infrastructure | buying puts a copy with the vendor; building means writing what the engine already does |
| you need to change how the engine behaves | the vendor will not change it for you, and writing an engine is not your job |
| the team already operates the same engine for something else | their advantage shrinks, because adopting's operation line is mostly paid already |

The last row is the one that most often changes the sum. If another Coreto team already ran the
same engine, the operation line would be shared with work already being done, and the upgrades
would happen anyway. No team at Coreto does, so the full 30% would land on the Catalogue team.

## Coreto's answer

For search, none of the three reasons applies. Coreto's events are public — they are shows for
sale — so a vendor holding a copy is no concern; nobody needs to change the engine; and nobody at
Coreto runs one today. Adopting would mean paying the most of the three to become the operator
of something that is context.

Davi wrote one sentence about it in the note to Helena:

> **Adopting was considered and rejected**: it is R$ 146,520 dearer than buying over three years,
> nearly half of its R$ 579,600 is people's hours, and it would make the Catalogue team the
> operator of a search engine Coreto does not need to control.

Write the rejected options into a recommendation, with their numbers. Somebody will ask about the
open-source option next year, and a sentence with a figure in it answers the question once.
Lesson 17 gives that habit a format, the architecture decision record.
