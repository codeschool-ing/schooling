---
title: Keeping the suite alive
version: 1
---

A regression suite is often treated as a thing that is written once, at the end of the first
release, and run unchanged forever after. **A suite left alone decays in two directions at once**:
it misses the parts of the product that grew after it was written, and it keeps running cases for
parts that changed or went away, which fail for reasons nobody cares about. After a few releases
people stop believing it, and a suite nobody believes is skipped. Keeping one useful is a small
amount of work after every release, and four habits cover most of it.

## Add what the release taught you

**Every fixed defect adds its retest to the suite.** Lesson 9 verified two fixes on 1.1: six
tickets accepted, and 15% for a member booking five. Both retests join the regression suite now,
with their neighbours, because section 02 named the way a fix leaves: somebody's later edit takes
it out again, and the only thing that notices is a case that keeps asking.

**Every defect that reached a release adds the case that would have caught it.** The student
discount is the instructive one. The suite did catch it, because the eight rules of the discount
table were in it, which is the argument for keeping whole tables rather than a convenient sample.
But the regression is now a known way this function fails, so rule 7, a member student booking two,
gets a note beside it: *regressed in 1.1*. A case with a history is a case nobody prunes by
accident.

## Take out what no longer tells you anything

A case belongs in the suite while it can still fail for a reason that matters. Three kinds stop
qualifying:

- a case for a feature that was removed, which now fails every run and teaches everyone to read
  red as normal;
- two cases that check the same thing by the same route, where one is kept and the other goes;
- a case whose expected result was a decision that has since changed. If the theatre decided that
  students get 40%, the eight rules get a new expected result on the day the decision is made, not
  on the day somebody runs the suite and reports a defect against the new rule.

The last one is the most common and the most expensive to miss. **A suite whose expected results
are out of date reports correct behaviour as a defect**, and every false report spends a
developer's time and some of the suite's credibility.

## Keep it in tiers

Not every case runs on every build. A common arrangement has three tiers:

| tier | what is in it | when it runs |
|---|---|---|
| core | the smoke list, and one case per high risk | every build |
| by change | the cases the impact analysis picks, as section 03 did for 1.1 | every build that claims a change |
| full | every case in the suite | before a release, or on a schedule |

Each case carries what decides its tier: the risk it covers, A to E for boxoffice, and the area it
tests, so that "everything about price" or "everything for risk C" is a filter rather than an
afternoon of reading. Lesson 18 shows the tools that hold suites like this; a spreadsheet with a
column for each is how most teams start.

## Record results per build

A result without a build number is a result nobody can compare. **Keep the results as a grid of
cases against builds**, and a regression becomes something you can see:

| case | 1.0 | 1.1 |
|---|---|---|
| member, student, 2 tickets: 50% | pass | **fail** |
| member, 5 tickets: 15% | fail (25%) | pass |
| member, 6 tickets: an order | fail (refused) | pass |
| quantity not a number: a sentence, R7 | fail (500) | fail (500) |

Read along a row and each case has a history: fixed, regressed, still open. A pass that turns into
a fail between two columns is a regression without any further argument, and a fail that never
changes is a known defect waiting for its fix. This grid is also the first thing anybody asks for
when a release is being decided, which lesson 19 turns into a one-page report.

When the full tier stops fitting into the time before a release, and with a release every week it
will, the cases that run on every build and never need a person's judgement are the first
candidates for automation. Lesson 13 shows what an automated test at the smallest scale looks like,
and the `web-automation` course automates checks like these through the browser. Until then, the
suite is run by hand, and it is kept short by the decisions above rather than by skipping its end.
