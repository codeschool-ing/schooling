---
title: Decision drivers and the options you did not choose
version: 1
---

**A record that names only the option chosen tells the reader what was done; one that names the
options considered tells them what was known.** The second is what stops a successor from
"discovering" the alternative that was already tried, and it is what lets a reader judge the
decision rather than take it on trust.

Nygard's original format folds the options into the context. **MADR**, *Markdown Any Decision
Records*, a widely used template maintained since 2017, gives them sections of their own, and its
structure is worth borrowing even if you keep Nygard's headings:

- **decision drivers**: the few forces that will decide between options, stated as criteria;
- **considered options**: each one named, in a line;
- **pros and cons of each option**, measured against the drivers;
- **decision outcome**: the chosen option, and the one-sentence reason it wins.

Recent versions of MADR also ask how the decision will be **confirmed**: what review, test or
measurement will show it was followed. Lesson 11 returns to that idea.

## Drivers first

The drivers are chosen **before** the options are compared, from the forces in the context. For
Carcará's seat holds, four came out:

1. **D1 exclusivity**: two passengers never hold the same seat;
2. **D2 load**: hold traffic must leave the booking database;
3. **D3 operations**: nothing the Platform team cannot run on a Friday night;
4. **D4 cost of change**: weeks of work, not months.

Fixing them first matters because otherwise the comparison drifts toward whatever the author
already preferred: each option gets judged on the criterion it happens to win.

## Comparing three options honestly

| | D1 exclusivity | D2 load | D3 operations | D4 change |
| --- | --- | --- | --- | --- |
| **A. keep holds in PostgreSQL, tune the indexes** | yes, by unique constraint | no: still 40% of writes | yes, nothing new | yes, days |
| **B. holds in Redis, one key per seat with a 10-minute expiry** | yes, by set-if-absent | yes: none reach the database | yes: Platform runs Redis already | yes, about three weeks |
| **C. a separate seat-inventory service with its own database** | yes | yes | no: a new service and store to run | no, a quarter |

Two habits make a table like this honest:

- **Write the losing option's case as its supporters would.** Option A is not *do nothing*; it is
  *the simplest system, with no new moving part*, and that is a real strength the table should show.
- **Say what each option costs, not only what it gains.** Option B gives up something that the table
  above does not even have a column for: holds now live in a store that can lose data on a restart.
  That belongs in the consequences, and the next section is about writing it down.

## When there was only one option

Sometimes there truly was one, because a regulation, a contract or an earlier decision fixed it.
Say so, and link to what fixed it: *we use the payment company chosen in ADR-0003; no other was
considered*. A record without options is fine; a record that pretends to have options it never
weighed is not.
