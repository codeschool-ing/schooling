---
title: What to measure, and what each number hides
version: 1
---

The first number anybody reports about a security programme is the count of findings: "the
scanners found 509 issues this year". It is the easiest number to produce and the hardest to read.
**A count of findings measures how many scanners are pointed at how much code, and how noisy they
are.** It goes up when a team adds a scanner, which is good news, and down when a team stops
running one, which is the worst news there is. A number that moves the same way for opposite
reasons cannot tell anybody how things are going.

The pipeline you built over nineteen lessons produces findings. This lesson is about what to do
with them once there are hundreds, across teams, over a year: which numbers answer a real
question, and how each one can lie.

### Four questions, and the number for each

Every useful security metric answers one of four questions. Write the question down before the
number, because the question is what tells you whether the number is the right one.

| question | the number | it hides |
|---|---|---|
| How fast do we fix what we find? | time to remediate, per severity: the median, and the 90th percentile | the findings still open, which have no time to remediate yet |
| Do we keep our promises? | the share fixed within the SLA, per severity, and the open findings already past it | whether the SLA itself is sensible |
| What is waiting? | security debt: the open findings, by severity and by age | the targets nobody scans, which have no findings to wait |
| Where are we blind? | scan coverage: the targets each scanner runs on, out of the targets that exist | whether anybody reads what a scanner reports |

Read the right-hand column as part of the definition. Each number is blind in a particular
direction, and the next number in the table is usually the one that looks there. Time to remediate
cannot see open findings; debt can. Debt cannot see an unscanned repository; coverage can. **That
is why one number on its own is never the report**: every one of them can be made to look good by
moving the problem into the column it cannot see.

A fifth view sits across the other four: the **trend**. Findings opened and closed per month or
quarter, and how many were open at the end of each. A debt of sixty is a different situation if it
was ninety last quarter or thirty.

### Decide what a finding is before you count one

Two scanners and two days can describe the same problem as four findings or one. Lesson 8 met the
image scanner reporting one CVE once per package that carries it, four rows for one fix. Lesson 11
ran two tools over the same image and counted differently. Before a number leaves the team, settle
three things:

- **The unit.** A finding is one problem on one target that one change fixes. Duplicates across
  packages of the same source, or across two tools, are merged before counting.
- **The opening date.** The day a check first raised it, which the pipeline's logs record. Not the
  day somebody triaged it, which would hide the time it sat unread.
- **The closing date, and the way it closed.** Lesson 1 drew three ways out of triage: fixed and
  verified by the same check passing, excepted until a date, or a false positive. A record that
  stores only "closed" has thrown away the difference between a fix and a decision not to fix,
  and the section on Goodhart's law shows what that costs.

### Where the data comes from

Everything in the table can be computed from two lists. **The findings**, one row per finding, with
the target, the tool, the severity, the two dates and the resolution. And **the inventory**: every
repository and image that exists, with the scanners that run on each. The findings come out of the
pipeline, and a scanner's JSON output plus the run's date is enough to build them. The inventory is
harder, and it is the one most programmes do not have, because nothing produces it on its own:
somebody has to list what exists, including what was never put through a pipeline.

The rest of this lesson builds both lists for a made-up company of four teams, with a program short
enough to read, and measures them with a second one. You can run both and get the same numbers
quoted here.

### Who the numbers are for

Different readers need different cuts of the same data. The team needs the open list, sorted by age
and SLA, because that is their work. The engineering lead needs time to remediate and debt per team,
to see where help is needed. Whoever answers for risk to the business needs coverage and the debt
past SLA, because those say how much is unknown and how much was promised and not done. The last
section of this lesson comes back to this, once the numbers exist.
