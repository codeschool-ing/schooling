---
title: A checklist for a new source
version: 1
---

**Before a new source is copied for the first time, every question in this lesson gets an answer
written down.** A written answer can be checked against what happens next month; an answer that only
existed in a meeting cannot. Here is the list, filled in for Caio's request, the dock sensor readings.

| question | the answer for the dock sensors |
|---|---|
| **what is it for?** | Caio's demand model, retrained on Sunday nights; Marta's report on empty stations |
| who owns the source? | the team that runs the sensors' server; they keep two days |
| rows a day | 216,000 today; 354,240 with the eight new stations |
| bytes a row | 102.6 in JSON Lines, measured on an hour's sample |
| a year, kept | 8.1 GB today, 13.3 GB with the new stations |
| how fresh? | yesterday, complete, by 07:00; nobody here needs the minute |
| pull or push? | pull, once a night; the server offers nothing else |
| full or incremental? | incremental by the reading's time, with an overlap for readings that arrive late |
| checks on the file | the expected columns; a count of readings per station |
| checks on each row | a known station and dock; a time inside the day; a voltage between limits agreed with the owner |
| where rejects go | a quarantine file a day, read by Davi on Monday mornings |
| reconciled against | the server's own count of readings per day |
| what it costs | storage is small; any dashboard over it reads one day, not the year |
| personal data? | none: a reading describes a dock, not a person |
| how long it is kept | raw for good; the rest decided with Caio once the model exists |

Three answers are worth a second look. **The first row comes first** because every other answer
depends on it: "how fresh" means nothing until somebody says what for. The owner's two days are a
deadline, since a pipeline that is down over a long weekend loses data nobody can collect again. And
the personal-data row is short here but is the longest row for rides, which carry a customer, a place
and a time; the same list for the rides table would end with section 09's three ways to need less.

## The list is a conversation

Most of these answers do not come from the data. They come from Caio, from Marta, from the sensors'
team and from the bill, and the list is the way to make sure each of them was asked. Several of them
belong in the data contract with the source's owner that lesson 4 described: the columns, the counts,
the limits, and what happens when a delivery breaks one of them.

Two answers on this list are about time — how fresh, and when a reading counts as late. Lesson 8 takes
both further: what changes when data is processed as it arrives instead of once a night, and what to
do with an event that turns up after its window has closed.
