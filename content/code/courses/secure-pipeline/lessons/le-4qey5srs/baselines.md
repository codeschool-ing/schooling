---
title: Old findings, new findings and exceptions that expire
version: 1
---

linkbox is small, and its pipeline met every finding one at a time. A real service adopting a
scanner meets them all at once: three hundred findings on the first run, in code written over
five years by people who have left. Breaking the build on all of them stops the team on day one,
and the gate is switched off by day three. Warning on all of them buries the next real finding
under three hundred old ones. **The way out is to separate new findings from existing ones**, and
to treat the two differently.

### Baselines

A baseline is a record of the findings that existed when the scanner arrived. The gate then breaks
only on findings that are not in it, which is the "now, in the change" half of the rule made
mechanical: whoever pushes is answerable for what they added, not for the history. The scanners of
this course each have a form of it:

@@CAPTURE baselines@@

gitleaks reads a previous report and leaves out the findings in it. Semgrep compares against a
commit and reports only what is new since then. pip-audit has no baseline at all, only
`--ignore-vuln`, one advisory at a time and for ever, which is why this lesson wrote a gate.

**A baseline has no dates and no names.** Every line in it is a finding somebody decided not to
fix today, recorded in a file nobody is responsible for, with no day on which the decision is
looked at again. Left alone it never shrinks, and an old finding in it is as exploitable as a new
one. So a baseline is a starting point with a plan attached: a number of findings, an owner for
the number, and a budget for bringing it down, measured the way lesson 20 measures security debt.

### Exceptions, which a baseline is not

The exception file of this lesson is the other tool, for the single finding a team has decided to
live with for a while. Its lines carry what a baseline lacks: **a date, a reason and an owner**.
The owner is not a field in the file. It is whoever committed the line, and Git already records
that:

@@CAPTURE owner@@

`git blame` names the commit behind each line, and the commit names its author and day. The name in
the reason is a courtesy for the reader; the commit is the record nobody can forget to fill in.

@@FIGURE expiry@@

Four rules keep exceptions from turning into a baseline by another name:

1. The date is short, weeks rather than a year, because a decision ages as fast as the code around
   it. The one in the last section ran four weeks.
2. The gate warns in the last week, so the people who wrote it see the date coming in the normal
   course of their pushes.
3. An expired exception is ignored, and the finding breaks the build exactly as before. Renewing
   one is a new commit with a new date and a reason that says what changed, read by a reviewer.
4. A line without a reason is refused: the gate cannot split it into three fields, Python raises,
   and the build breaks.

### Where this leaves the pipeline

Every stage now answers in three statuses, the last line counts the warnings, and a stage that did
not run breaks the build. The composition gate knows the difference between a fix nobody applied,
an advisory nobody can fix, and a decision with a date on it. What the lesson cannot write into a
script is the reading: **a warning is only worth its place if somebody reads it**, and the number
of warnings a team actually reads is smaller than the number a scanner can produce. Lesson 8 puts
an image scanner in front of the same question, with findings in a base image that have no fixed
version at all.
