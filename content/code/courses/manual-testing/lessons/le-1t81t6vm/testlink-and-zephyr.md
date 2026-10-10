---
title: TestLink, the open-source one, and Zephyr, the one inside Jira
version: 1
---

The two tools in this section answer the same need as the two before it from opposite directions.
**TestLink is open source and lives on a server you run yourself. Zephyr is sold as an extension
of Jira and lives inside the tracker your team already uses.** Neither was run for this course;
what follows is what kind of tool each is and what that means for the person using it.

## TestLink

TestLink is a web application released as open source, written in PHP and kept in a database, and
anyone may download it and install it on their own server. Its model is the one this lesson has
been describing, under its own names. A **test project** holds the **test specification**, which
is the repository of suites and cases, and may hold the **requirements** the cases cite. A **test
plan** chooses cases for a release, and it is executed against a **build**, so the result of a
case always says which build it came from.

What it costs is not a licence. **Somebody has to install it, keep it updated, back up its
database and answer when it is down**, and in a small company that somebody is often the tester.
Its interface is older in style than the commercial tools', and the integrations a team takes for
granted elsewhere may need configuring by hand. In return the data never leaves the company's
own machines, which some organisations require, and nothing stops a team from trying it for a
month to learn what it actually wants from a case tool.

## Zephyr

Zephyr is a family of test management products sold by SmartBear, and the ones most testers meet
are apps installed in Jira. Instead of a second web application beside the tracker, the cases,
the **test cycles** that group them for a release, and the **executions** that record each result
all live in the same Jira project as the stories and the defects. In some editions a test is
itself a Jira issue of its own type, so it can be searched, linked and put on a board like any
other issue.

The attraction is that there is one place. **A failed execution and the bug it produced are
linked inside one tool**, and the story whose acceptance criteria the case checks is one click
away, so the traceability of section 01 comes from links the team is already making. A team that
lives in Jira does not have to persuade anybody to open a second tool.

The cost is the other side of the same fact. The case model takes the shape of the tracker, and a
repository of two thousand cases inside a project that also holds the team's work is a lot of
issues for everybody else to filter out. Zephyr also goes wherever the company's Jira goes; if
Jira is replaced, the cases move with a migration rather than staying put.

## The same model, four names

Everything in this lesson so far comes down to one table. The words differ; the shape does not.

| tool | kind | where it lives | the repository | a run is called |
|---|---|---|---|---|
| TestRail | commercial | its own web application, hosted or on your servers | suites and sections | a test run, grouped in a test plan |
| qTest | commercial | its own web application | test design, in modules | a test run, inside a test cycle |
| TestLink | open source | a server you run | the test specification | a test plan, executed against a build |
| Zephyr | commercial, a Jira app | inside Jira | tests in a Jira project | a test cycle and its executions |

**Choosing among them starts from where the team already works**, not from a list of features.
A team whose day is spent in Jira is pulled towards Zephyr. A testing group serving several
products and several trackers is pulled towards a standalone tool such as TestRail or qTest. A
team with no budget and somebody willing to look after a server can run TestLink. And a team of
one tester and seventeen cases may need none of them yet, which is where section 04 of this lesson
starts.
