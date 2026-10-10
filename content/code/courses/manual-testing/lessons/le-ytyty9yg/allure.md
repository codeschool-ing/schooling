---
title: Allure, a report built from results
version: 1
---

A file of results is not a report. Section 02's XML holds everything about a run and is still not
something anyone opens to find out how the release is going. **A report tool reads result files
like that one and builds pages people can browse: totals, failures with their evidence, and how
each case did over the last runs.** Allure Report is the open-source one most often met in teams
that automate, and it is a good example of the kind. This course did not run it, and nothing in
this section asks you to install it.

## How it is fed

Allure does not run tests. The tests run in whatever framework the team uses, and an **adapter**
for that framework writes each result into a folder as the tests run: the outcome, the steps the
test went through, how long each took, and any attachment, such as a screenshot of the page at the
moment of failure or the text of the response. Adapters exist for the common frameworks in several
languages, and Allure's command-line tool can also read JUnit XML, the format of section 02.

The command-line tool then turns that folder into a **static website**: plain HTML files that can
be opened from a disk, published by the CI server after every run, or attached to a release.

## What the pages add to the XML

**An overview.** The first page answers "how did the run go" with totals by status and a chart, the
same seventeen results as section 02's file in a form that takes two seconds to read.

**The failure, with its evidence.** Clicking a failed test shows its steps, the step that failed,
the message, and the attachments. For a web application the screenshot is often the whole defect
report's evidence, already captured, which is lesson 15's subject reached from the other side.

**History and trends.** When the results of earlier runs are kept and handed to the next report,
each test shows its recent outcomes, and the overview draws a trend across runs. That is the
results history of lesson 18 rebuilt from automated runs. Without the earlier results the report
knows only today.

**Grouping by behaviour.** Tests can be labelled with the feature or the story they check, and the
report groups them that way as well as by suite. Labelled by requirement, boxoffice's results would
show R5 with three tests and one failure, which is the traceability view of lesson 18 again.

**Categories and flaky tests.** Failures can be sorted into categories by their messages, so that
twenty failures with the same cause read as one problem, and a test that passed on a retry after
failing is marked as **flaky**: a test whose result cannot be trusted on a single run.

## Who it is for

Allure's reader is the team: the developer who needs the failing step and its screenshot, and the
test lead who needs to see that the same three tests have failed for a week. It answers their
questions well. **It does not answer leadership's**, for the reason section 01 of this lesson gave
about the pass rate: a page of green and red slices says how many tests failed and not whether the
theatre can open its booking on Friday. A manager sent a link to a report like this either learns
to read it, which is the tester's job handed upwards, or looks at the colour of the chart and
decides on that.

## The other places results are shown

Allure is one choice among several. Most continuous-integration servers draw a results page from
JUnit XML on their own, which is enough for a team that only needs to see what failed in the last
build. The case tools of lesson 18 keep automated results beside manual ones, so that a run has
one answer whichever way its cases were executed. And a team with no tooling at all has a file like
`results-1.1.xml` and a person who reads it.

The choice among them follows the same rule as the choice of a case tool: start from who reads it
and what they need to decide.
