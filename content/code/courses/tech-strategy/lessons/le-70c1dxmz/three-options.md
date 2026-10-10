---
title: Three ways to get search
version: 1
---

Coreto's buyers find a show by typing into a search box, and the box is bad. It runs `LIKE`
queries against the events table in `coreto-core`'s Postgres database, so a band's name typed with
one letter wrong finds nothing, and a festival with a long line-up is found only under its own
name. Júlia Sato, the head of product, has asked for search that forgives typos and ranks results
sensibly. The Catalogue team has to say how.

**The usual first question is whether the team can build it.** It can: the Catalogue team is good,
and full-text search is a solved problem. That answers a different question. Whether a team can
build something says nothing about whether building is the cheapest way to have it, or the best
use of the hours it would take. The decision has three options, and each spends its money in a
different shape.

## The three options

**Build** means better search inside the database Coreto already runs. Postgres has full-text
search of its own — an index over the words of each event, ranking, and extensions for misspelt
words — so the team would write the indexing, the queries and the ranking rules, and own them from
then on.

**Buy** means a hosted search service. Coreto sends every change to its events to the vendor's
API, and the search box queries the vendor. The vendor runs the machines, the index and the
upgrades, and sends an invoice every month.

**Adopt** means an open-source search engine running on Coreto's own servers. Nobody is paid for
the software, and nobody else runs it either: the engine, its cluster and its upgrades are the
team's.

## What each one costs, line by line

Ask the Catalogue team to price each option and the answer comes back in three kinds of money:
work done once, people's time every year, and money paid to somebody else every year. Every
figure below is in reais, at Coreto's R$ 150 an engineer-hour and R$ 264,000 an engineer-year
(1,760 hours).

| | build | buy | adopt |
|---|---|---|---|
| work done once, in year 1 | 960 h (R$ 144,000) | 240 h (R$ 36,000) | 480 h (R$ 72,000) |
| people, every year | a quarter of an engineer (R$ 66,000) | a twentieth of an engineer (R$ 13,200) | 30% of an engineer (R$ 79,200) and 80 h of upgrades (R$ 12,000) |
| paid out, every year | database capacity, R$ 3,000 a month (R$ 36,000) | the licence, R$ 9,000 a month (R$ 108,000 in year 1), rising 10% a year | servers, R$ 6,500 a month (R$ 78,000) |

Each cell is an estimate somebody can defend, and it is worth knowing what is inside it.

**Building is mostly the first year's work.** The 960 hours are more than half an engineer-year: the index, the queries, the typo handling, the ranking, and the testing against
real searches. After that, a quarter of an engineer — 440 hours a year — keeps it working: tuning
the ranking when somebody complains, adding the next thing product asks for. The database needs
R$ 3,000 a month more capacity to carry the new index and the query load.

**Buying is mostly the invoice.** The vendor quotes R$ 9,000 a month, and its contract raises the
price 10% a year, so the licence is R$ 108,000 in year 1, R$ 118,800 in year 2 and R$ 130,680 in
year 3. Integration takes 240 hours: keeping the vendor's copy of the events in step with
Coreto's, wiring the search box to the API, and a fallback for when the vendor is down. A twentieth
of an engineer, 88 hours a year, watches that the copy stays in step and handles the vendor's API
changes.

**Adopting is mostly people.** The servers cost R$ 6,500 a month for a cluster with replicas.
Setting it up and integrating it takes 480 hours. Then 30% of an engineer, 528 hours a year,
operates it — on-call, disk space, backups, rebuilding an index that went wrong — and another 80
hours a year go on upgrades, because an engine left on an old version stops receiving security
fixes.

## What each one buys

The three options are three trades, and naming them helps more than any single number.

**Building trades engineers' time for control.** Coreto decides exactly how results are ranked
and owns every line, and it pays in hours: up front, and a slice of a person for as long as the
feature lives.

**Buying trades money for time.** The integration is a quarter of the build's hours, so search
improves in weeks rather than months, and Coreto stops owning a problem that other companies
have solved. The price is an invoice that rises every year, and a vendor between Coreto and its
own search box.

**Adopting trades operation for control of the code.** Coreto can read, change and keep the
engine, and nobody can raise its price. The cost is that the team becomes the operator of a piece
of infrastructure it did not write.

The three also **spend at different times**, and that is what the next two sections turn on.
Building is expensive in year 1 and cheap after. Buying is cheap in year 1 and dearer every year.
Adopting is expensive every year. A comparison made on the first year's figures alone picks the
option that is cheapest to start, which says little about the option that is cheapest to have.
Before the sheet, though, the next section asks the question that often decides without one:
whether search is something venues choose Coreto for.
