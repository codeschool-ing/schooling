---
title: Which part of Roda Livre needs which
version: 1
---

**CAP is chosen per piece of data, not per company, and Roda Livre needs both answers in different
places.** The mistake to avoid is choosing one database for its letters and then living with that
choice for every kind of data the company has. The question goes to each piece of data in turn:
if both sides of a cut said yes at once, could the two answers be merged afterwards?

## Five pieces of data, five answers

| data | during a cut it should | why |
|---|---|---|
| a ride's payment | **refuse** | a charge taken twice or recorded wrongly cannot be merged; it becomes a refund and a phone call |
| which customer holds bicycle `B017` | **refuse** | one bicycle, one rider; two "yes" answers put two people at one dock |
| the dock map in the app | **answer** | a map slightly behind still sends people roughly right, and counts merge |
| readings from the dock sensors | **answer** | a reading is a fact about one moment, and a duplicate can be dropped later by its id |
| Marta's morning report | **neither, by design** | it is computed from a copy kept hours behind |

The first two are why Roda Livre's app keeps payments and unlocking in a database with one primary
and a payments provider that is itself the record of every charge. The middle two are why the map
and the sensor readings can sit in a store that accepts writes on any machine. Neither choice is
the better one. **Each is right for the data it holds, and wrong for the other.**

## The last row is the data platform's

Marta's report is the row this course has been about, and CAP does not apply to it in the way it
applies to the others. The pipeline of lesson 3 copies yesterday's rides out of the app's database
once a night. Every number the report shows is therefore up to a day old — and nobody minds,
because that delay was chosen and written down.

In PACELC's terms, a data platform has made the *else* choice as far towards latency as it goes:
it never waits for the source to agree, and it accepts being behind by a known amount. **What it
promises instead of linearisability is freshness**, which lesson 2 turned into a target that can
be measured. For Marta's report it might read: every ride up to midnight is in the report by
seven.

Two duties follow, and both have appeared in this course already.

- **Say how stale.** A dashboard that shows how old its data is turns a stale number into an
  honest one. Lesson 2's freshness target is that promise made in public.
- **Make catching up safe.** A platform that is behind will be caught up, by a re-run, a
  backfill or a retried load. Lesson 3's ingest that could be run twice without counting twice,
  and lesson 8's effectively-once delivery, are what make that safe — the AP world's merge, in a
  pipeline.
