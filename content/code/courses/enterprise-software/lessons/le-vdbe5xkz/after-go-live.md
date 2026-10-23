---
title: After go-live: hypercare, the first payment and the archive
version: 1
---

The cutover night ends at 10:00 on Sunday, and it is tempting to call that the end of the
migration. It is the end of the part that could be rehearsed. **What a migration got wrong shows up
when the business uses the data for the first time**, and some of its uses come round once a
month: the close, the payment, the statement a farm reads. The weeks after go-live are planned with
the same care as the night, because that is when the remaining mistakes are found.

## Hypercare

**Hypercare is a fixed period of extra support after go-live**, with the people who built and
migrated the system kept close to the people using it. At Serra Alta it was set at eight weeks,
long enough to cover two payments, and it had a shape written down before the cutover:

- a call every morning at 08:30 for the first two weeks, then twice a week, with the migration team,
  Sebastião, Rui's integration team, Cláudia's quality team and finance;
- one list of issues, each with a severity and an owner, so a problem reported twice is one problem
  and nothing reported is lost in somebody's inbox;
- the field technicians who visit farms, briefed in advance, because a farmer who thinks the litres
  on a statement are wrong calls the technician first;
- an exit written in advance: two payments with no farm paid wrongly, and no open issue above the
  lowest severity.

The exit criteria matter for the same reason as the go/no-go criteria in the previous section.
**Hypercare that ends when people get tired of it ends with its problems still open**, and they
then belong to a support team that never saw the migration.

## The old system, read-only

Coleta did not disappear at 10:00. It stayed up, **read-only**, for twelve months: nobody could
change anything in it, and anybody could look something up. In the first weeks that was used every
day. A farm disputing July's payment is asking about a month Coleta calculated, and the answer is
in Coleta's screens, with Coleta's rules. A field technician checking whether a farm's tank used to
be collected every day or every other day looks it up there too.

Read-only is a decision with a cost: the IBM i machine, its licences and Sebastião's time for
another year. It buys an answer to every question about the past without anybody having to
migrate the whole past. The `legacy_code` the mapping kept in the new system is what makes the two
usable side by side. When the year is over, what is still needed goes to the archive, and lesson 13
covers switching the machine off.

## Parallel reports

During hypercare, the numbers that the business already watched were watched twice: once from the
new system, and once from a source the migration did not touch.

**Litres collected against litres received.** Every day, the litres the trucks collected at the
farms are compared with the litres the plants measured when the trucks unloaded. Under Coleta, the
two differed by a small, steady margin that everybody knew. After the cutover the same comparison
ran on the new system's figures. **A step change on the day of the cutover would have pointed at
the migration**, and there was none.

**SAP against the new system.** SAP's goods receipts of milk are now created from the new system's
nightly file. A daily report of litres by plant from SAP, beside the same report from the new
system, shows whether the integration and the system agree. In the first week they disagreed once,
on the Monday, by the litres of eleven farms: their readings had been held by the handhelds during
the window and released after 06:00, so they reached the new system on Sunday and SAP on Monday
night. That was correct, and worth knowing.

## The first close and the first payment

The first real test is the first month-end. Finance closes August in the first five working days
of September, and the milk bought in August is the largest cost in Serra Alta's books. Fourteen days of
that month's collections were migrated and seventeen were taken by the new system, so the close
is where any gap between the two halves shows. Finance compared August's litres with July's and with the
same month the year before, and closed on time.

**The first payment on the 10th is the test that matters most**, because it is the first time the
new system decides how much money 1,900 farms receive, and the point of no return of the previous
section comes just before it. Before the run was posted, finance compared each farm's August
payment with its July payment and checked by hand every farm whose payment had moved by more than
15%. There were 38. Thirty-five had a reason in the data: more litres, fewer litres, a better or
worse laboratory result. **Three had no reason**: their fat result was exactly 3.50%, and the new
system put that in the lower band of the quality bonus where Coleta had put it in the upper one.
Lesson 13's three months of parallel running had never contained a farm at exactly 3.50%, so
neither the parallel run nor any reconciliation could have seen it. The rule was corrected and
signed by Cláudia, the three amounts were recalculated, and the bank file went on the 9th.

That is the kind of fault hypercare exists for. **A reconciliation proves that the data arrived;
only using it proves that the system does the right thing with it.**

## Archiving the legacy data

The data that did not move still has to be kept for as long as the law and the business need it.
Lesson 5's ideas about records apply: a retention period, a records owner, and a date on which the
records are destroyed.

Serra Alta's archive holds three things. **The history outside the migration's period**: the 182
farms and about 10.5 million collection rows, with the 1,312 orphans flagged. **A full snapshot of
Coleta at the moment of the freeze**, so that any question about what Coleta held can be answered
from the archive once the machine is gone. And **a description of every field**, written by
Sebastião, because the only complete statement of what each field means is the RPG program that uses it,
and its author retires in 2028.

The format is the one that will still open in twenty years: plain text files, CSV with a written
layout, rather than a backup that needs an IBM i to restore. The archive is reconciled against
Coleta like any other target, by counts and totals per year, before the machine is switched off.
The records owner is finance, and the retention period and the disposal date are
written on the archive itself. An archive with no end date is kept forever by default, and data
kept forever is a cost, and under the LGPD a liability when it holds people's tax ids.

**A migration is finished when the old data has a home, an owner and an end date**, not when the
new system goes live. Everything between those two moments is part of the plan.
