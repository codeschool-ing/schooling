---
title: Measuring the interest
version: 1
---

No time log has a column called interest. **It has to be put together from three sources**, each of
which sees part of it: the tax on changes that touch the debt, the hours spent on the incidents it
causes, and what engineers record while they work. Davi used all three for the seat-hold debt, and
the 31 hours a sprint is what they added up to.

The method most teams reach for first is a meeting: ask the engineers how much each debt costs them.
The answers come back confident and they are not a measurement. The loudest complaint wins, and the
debt that annoys people most is rarely the one that costs most. The flaky suite is irritating every
day, the reporting replica is embarrassing to show a new hire, and neither feeling says how many
hours went where. Interest is measured on the work, not on the mood.

## The tax on every change

The largest part of most interest is a **tax on changes**: work that touches the debt takes longer
than similar work that does not. At Coreto, a change to how long a seat stays held needs a reviewer
from each team whose feature depends on the hold, a rehearsal against a copy of production, and
often a second attempt. A change of the same size to the Catalogue team's search code needs none of
that.

To measure it, take the changes merged over the last few sprints and split them by whether they
touched the module. Compare the time from first commit to deploy for changes of similar size on
each side. The difference, multiplied by the number of changes that touched the module, is the tax.

Two cautions keep that number honest:

- compare like with like, because a two-line fix and a new feature do not belong in one average;
- count the reviewers' hours as well as the author's, since at Coreto most of the seat-hold tax lands
  on the people asked to review.

## Incident hours

The second part is the cost of what breaks. Every incident traced to the debt costs hours: the people
paged, the investigation, the fix, the follow-up. Coreto's incident log already records who worked on
each incident and for how long, so this part is the easiest to count. Filter the incidents whose cause
names the reservation module, add the hours, and divide by the number of sprints the log covers.

**Count the hours here, not the sales the incident lost.** Lost sales during a failed on-sale are
real, but they are the risk lesson 20 puts a price on. Counting them as interest as well would count
the same failure twice, once in each place, and the case would look stronger than it is.

## What engineers record

Some interest leaves no trace in a pull request or in the incident log: the morning lost working out
why the end-to-end suite failed when nothing was wrong, the afternoon spent hand-editing a PDF layout
for a venue with an unusual ticket. For those, ask the people paying it to tag their own time for a
few sprints, with one label per debt — "rerun of the flaky suite", "PDF layout by hand".

It is crude, and it works, because the tagging happens during the work instead of being remembered a
month later. The flaky suite's 14 hours a sprint came mostly from this source: reruns and
false-failure hunts show up nowhere else.

| source | what it catches | where the data already is |
|---|---|---|
| tax on changes | slower reviews, rehearsals, second attempts | merge and deploy history |
| incident hours | pages, investigation, fixes | the incident log |
| engineers' tags | reruns, hand work, workarounds | nowhere, until somebody asks |

## How precise it has to be

Interest is an estimate, and it does not have to be exact to be useful. **What it has to get right is
the order of magnitude**, because the decisions it feeds compare debts whose interest differs several
times over.

Suppose Davi's 31 hours were twice the truth, and the seat-hold debt really cost 15.5 hours a sprint.
Its 320-hour principal would pay back in about 21 sprints instead of 10, which is slower, and it would
still rank far ahead of the reporting replica, which takes 50. An error of a factor of two left the
order where it was.

What does break the order is counting the wrong thing: a team's whole week on the module, say,
including new features that would have been written anyway. Only the extra counts, meaning the hours
that would disappear if the debt did.

## Write down how you got it

Put the method next to the number. "31 h a sprint, from merge times on changes touching the
reservation module, plus incident hours from the log, plus two teams' tags" invites a reader to
check it. A bare 31 invites them to doubt it, and a number nobody can check is the first thing cut in
a budget meeting. The next section turns the four measured interests into a sheet.
