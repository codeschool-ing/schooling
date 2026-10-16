---
title: Delivery: the stage everybody else sees
version: 1
---

**Delivery is the stage where the data finally reaches somebody who is not on the data team, and it
is the only stage the rest of the company ever sees.** Nobody at Roda Livre thanks Davi for a raw
directory. Marta notices the morning report, and she notices it most on the morning it is late or
wrong.

Delivery is easily taken to mean a dashboard. A dashboard is one form among several, and the
readers are not all people.

| form | who or what reads it | at Roda Livre |
|---|---|---|
| **a report** | a person, at a fixed time | the morning report: yesterday's rides, the busiest stations |
| **a dashboard** | a person, whenever they look | a screen in the operations room, refreshed each hour |
| **a feature table** | a model | for Caio: one row per station per hour, with the rides and the weather |
| **reverse ETL** | another operational system | the stations likely to run empty tomorrow, pushed into the app the van drivers use to rebalance bicycles |
| **an API** | a program, on request | the app asks "how busy is this station at this hour, usually?" and shows the answer |

**Reverse ETL** is the least obvious of the five, and the name says what it is: the curated result
goes back into an operational tool, the opposite direction to ingestion. The van drivers never open a
dashboard; the list appears in the app they already use. The design of dashboards is `analytics-bi`,
and building an API is `apis`.

## Delivery reads curated, and nothing else

**Every form of delivery reads the curated zone, not raw and never the app's database.** If the
dashboard counted rides from raw while the report counted them from curated, the dashboard would
include false starts and the report would not, and Marta would get two numbers for one question.
One curated table, read by every form, is what makes the five forms agree with each other.

## A delivery is a promise

**The moment somebody depends on a delivery, it carries a promise, whether or not anybody wrote it
down.** The morning report promises two things: that it is there by eight, and that "rides" means
what it meant last week. Break the first and Marta waits. Break the second — change the false-start
rule without telling anyone — and she compares this week with last week and draws a conclusion from
a difference the pipeline made up. Lesson 2 puts numbers on promises like these, as a freshness
target a team can measure.

That is why delivery sits at the end of the lifecycle and is designed first. **Who reads it, in what
form, by when, and with what definition** decides what the earlier stages have to keep, how often
they run, and which rules the transformation applies.
