---
title: What a case tool is for
version: 1
---

A case management tool is easy to picture as a filing cabinet: somewhere to keep test cases so
they are not lost in a folder of documents. Keeping them is the smallest part of the job. **What a
case tool adds is the separation between a case, written once, and its runs, each time it is
executed against a build, with the links between them and the requirements and defects either
side.** Everything the four tools in this lesson sell is built on that separation.

## Four things a tool keeps apart

**A repository of cases.** Each case has the shape lesson 2 gave it: an id, a precondition, steps,
an expected result, and the requirement it checks. The repository groups them into **suites**,
usually one per area of the product. Boxoffice would have four: accounts, booking, orders and the
pages themselves.

**Runs.** A run is a selection of cases executed against one build, and it holds **one result per
case**. Lesson 10's regression run on boxoffice 1.1 is a run: the cases it chose, the build it ran
on, and what each one did. The case is the same text in every run; only the result belongs to the
run.

**Results history.** Because the case is one object and its runs are many, the tool can show a
case's results across every run it has been in. On boxoffice the case that books two tickets for
Hamlet as a student passed on 1.0 and failed on 1.1. Seen as two documents, those are two facts;
seen as one row with two results, they are a regression, which is the thing worth noticing.

**Traceability.** A case cites a requirement, a failed result cites a defect report, and the tool
follows those links in both directions. Asked "is R5 tested, and is it passing?", it lists the
cases that cite R5 and their latest results. Asked "what does this defect threaten?", it walks
from the report back to the failed result, the case, and the requirement.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l18-trace\" aria-label=\"Four kinds of box joined by arrows. Requirement R5, students pay half, points to case TC-10, Student pays half, written once. The case points to two runs, each holding one result: the run on 1.0 passed, the run on 1.1 failed. The failed result points to a defect report, student discount lost. A line underneath says the same links can be walked in either direction.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15.0\" y=\"60.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"78.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirement R5</text><text x=\"90.0\" y=\"93.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">students pay half</text><rect x=\"200.0\" y=\"60.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"78.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">case TC-10</text><text x=\"275.0\" y=\"93.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Student pays half</text><rect x=\"385.0\" y=\"20.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run on 1.0</text><text x=\"460.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">passed</text><rect x=\"385.0\" y=\"100.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run on 1.1</text><text x=\"460.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">failed</text><rect x=\"560.0\" y=\"100.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">defect report</text><text x=\"635.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">student discount lost</text><path d=\"M165.0 86.0 L197.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M350.0 78.0 L382.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M350.0 94.0 L382.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M535.0 126.0 L557.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"275.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written once</text><text x=\"460.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one result per run</text><text x=\"635.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cited by the failure</text><path d=\"M15.0 196.0 L710.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"362.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">traceability: the same links, walked in either direction</text></svg>", "caption": "One case, written once, and its results in two runs. The links from the requirement to the defect are what lets a tool answer both \"is R5 tested?\" and \"what does this defect threaten?\"."}
```

## The results, and the one people confuse

Every tool has its own list of statuses, and every list contains four that mean the same thing
everywhere:

| status | what it says |
|---|---|
| passed | the case ran and the expected result happened |
| failed | the case ran and something else happened |
| blocked | the case could not run, because something it needs is broken |
| not run | nobody has run it yet in this run |

**Blocked is not failed**, and mixing them up corrupts every number built on them. If booking
answered every request with an error page, the case for the member discount could not get as far
as a price. Marking it failed says the discount is wrong, which nobody knows; marking it blocked
says the discount was not tested, which is true, and points at the defect that stopped it.
Lesson 15's report of the booking error is the one that gets fixed, and the blocked cases run
again afterwards.

## When a team needs one

A tester with seventeen cases and one release to look after keeps all of it in their head and in
a spreadsheet, and section 04 of this lesson shows that spreadsheet for boxoffice. The tool starts
paying for itself when one of these becomes true:

- more cases than one person can remember, so finding "every case that touches refunds" needs a
  search rather than a memory;
- more than one tester, so two people are recording results in the same run at the same time;
- more than one release or configuration to compare, such as lesson 7's four browsers, each a run
  of its own;
- somebody outside the team asking for evidence, such as an auditor in a bank or a hospital, who
  wants to see that each requirement was tested, on which build, by whom, with what result.

**A tool does not write the cases, and it does not choose them.** A repository full of cases that
say "check booking works" is a database of cases nobody else can run, which is lesson 3's
subject. And deciding which cases go into a run is the risk ranking of lesson 1 and the regression
choices of lesson 10. What a tool does well is keep the record those decisions produce, so that
the next release starts from it instead of from memory.
