---
title: TestRail and qTest, two commercial case managers
version: 1
---

**TestRail and qTest are dedicated case managers: web applications whose whole subject is cases,
runs and results, sold by subscription, that sit beside a defect tracker rather than inside it.**
A team using either keeps its stories and defects in the tracker of lesson 17 and its cases and
runs here, and the two are linked so that a failed result can point at a defect and back. This
course ran neither of them. What follows describes what kind of tool each one is and the words
each uses, which is what you need to find your way around one on your first day.

## TestRail

TestRail organises the repository as **suites** divided into **sections**, and each case lives
in one section. A **test run** is a selection of cases against a build, and every case in it gets
a result as the tester works through. A **test plan** groups several runs that belong together,
and the common reason is configurations: one plan for a release, holding one run per browser, is
the shape lesson 7's compatibility matrix takes once it is in a tool. **Milestones** tie runs and
plans to a release date, so the question "how far through 1.1 are we?" has a page that answers
it.

Two things about it matter more than the vocabulary. It links to the trackers teams already use,
Jira among them, so a tester marking a case failed can open the defect from the same screen and
the result keeps the link. And it has an API, so results from automated tests can land in the
same runs as manual ones. That is how a team whose regression suite is half automated still gets
one answer to "did 1.1 pass?" instead of two.

It is offered as a hosted service and as software a company runs on its own servers.

## qTest

qTest belongs to Tricentis, a company that sells a family of testing products, and qTest is the
part of that family that manages cases and runs. Its screens follow the path of a release:
**requirements**, which are often brought in from Jira rather than written twice; **test
design**, where cases are written and grouped in modules; and **test execution**, where releases
hold **test cycles**, and cycles hold the **test runs** that carry the results.

The difference from TestRail that a tester notices first is how much of the work is organised
around the requirement. Because the requirements are in the tool, coverage is a view rather than
a report somebody assembles: which requirements have cases, which cases ran in this cycle, which
failed. It is built for organisations testing many products with many teams, where that view is
the thing managers ask for every week.

## What they have in common, and what to look for

Both keep the four things of section 01 apart: the repository, the runs, the history, the
links. Both have the same four statuses, under their own names and with extras each team can add.
And both turn the results into charts: progress through a run, results by status, defects by
requirement.

**Neither one makes a case better than the text a tester writes into it.** The work you do in one
is the work of lessons 2 to 5: writing a case a stranger can run, choosing the values at the
boundaries, citing the requirement. What changes from a spreadsheet is that the run, the result
and the link to the defect are recorded the same way by everybody, which is where the numbers in
lesson 19 come from.

Choosing between the two is seldom a question of features. A company picks the one that fits the
tracker it already has, where it is willing to host its data, and what it costs, which this
course does not compare because it changes.
