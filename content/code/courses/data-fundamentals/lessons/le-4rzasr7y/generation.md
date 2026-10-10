---
title: Generation: data is born in a system built for something else
version: 1
---

**Almost no data is generated for the people who analyse it.** It is a by-product of a system doing
its own job, and it carries the shape of that job. Roda Livre's app writes a row for every ride
because it has to charge for the ride. The row holds what charging needs: which bicycle, from where,
when, for how long, and the price. It holds nothing that only a report would want, and it was never
asked to.

That is the first thing to understand about a source: **its owner built it for a purpose, and your
question is not that purpose.** At Roda Livre four systems generate nearly everything the data team
will ever touch.

| system | what it writes | what it was built for | who owns it |
|---|---|---|---|
| the app's database | rides, customers, the stations | charging customers and unlocking bicycles | the app team |
| the dock sensors | one reading a minute per dock: bicycle present or not | the map in the app | a hardware supplier |
| the payments provider | charges, refunds, failed cards | moving money | a company outside Roda Livre |
| the app itself | taps and screens: opened the map, searched a station | the product team's experiments | the app team |

Lesson 4 takes each kind of source in turn — a database, an API, a file, a log, events, sensors —
and what each one costs to read. This section is about what they have in common.

## What the generator decides for you

Whoever writes the data decides things that every later stage has to live with:

- **The clock.** The app at Roda Livre writes `started_at` as `2025-09-15 06:01`, a local time with no
  zone written beside it. Every reader has to know that it means Curitiba's clock. Lesson 1's
  Wednesday with 27 hours of readings is what happens when two generators disagree about that.
- **The units.** The price is in `price_cents`, an integer number of centavos. A sensor might send
  battery level as 0–100 one year and 0–1 the next.
- **The identity.** A ride is `R000174` because the app numbers them. If the app reused a number, no
  later stage could tell two rides apart.
- **What counts as a row.** The app writes a ride when the bicycle is docked again. A ride that is
  still going at midnight is not in that day's data yet.

None of these is the data engineer's choice, and **all of them can change without warning** when
the owning team ships a new version. Lesson 1 showed what a renamed column does to a program that
trusted it.

## A source keeps the present, not the past

**An operational system stores the current state of things, and updates it in place.** If a ride is
refunded, the app may set its price to zero. If a customer changes their e-mail, the old one is
overwritten. If a station is renamed, every old ride now points at the new name. The system is right
to work this way: its job is to know the truth now.

**The first copy the data team takes is often the
only history there is.** The dock sensors keep two days of readings; a copy that misses a night has
lost that night for good. That is why the next stage, ingestion, copies the data out on a schedule
and changes nothing in it, and why the stage after that keeps the copy.
