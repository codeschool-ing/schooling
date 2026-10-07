---
title: Reproducible, documented, versioned
version: 1
---

An analysis outlives the meeting it was made for. Six months later somebody asks where 41.5% came from, or
the board wants the same numbers for the second half, or the analyst has moved on. **An analysis that cannot
be rerun by somebody else is a one-off, however good it was.**

## What a handover contains

- **The data, or how to get it.** The query that produced the twenty-four rows, or the export, with the
  date it was taken.
- **The definitions**, the table of lesson 4, as a document rather than in the analyst's memory.
- **Every calculation as something that runs.** The spreadsheet with its formulas, not a copy of the
  values; a script, if the work was done in code.
- **The deliverables, dated.** The deck and the page as presented, and every later version with what
  changed.
- **A decision log.** One line per decision: what was decided, by whom, when, and why. *"27 October: extend
  to the capital from November. Paulo. Criterion met from week 4; guardrail held."*

## This course does it

Every number in this course is computed by a script, `sheet.py`, from a seeded generator, so that running it
next year prints the same values. Every figure is drawn by another, `figures.py`, from the same numbers. And
every spreadsheet formula quoted in a lesson is typed into LibreOffice Calc by a third, `lab.sh`, which prints
what Calc answered. **None of that is visible to a student reading a lesson**, and all of it is why a number
in lesson 11 and the same number in lesson 4 cannot disagree.

That is the standard to aim at, scaled down. You do not need scripts: a spreadsheet whose numbers all come
from formulas over one data tab is reproducible. What breaks reproducibility is the number typed by hand
into a slide, which nobody can trace and nobody updates when the data changes.

## Versions

Name versions by date, not by "final": `first-delivery-2025-08-15.pptx`, not `final-v3-REAL.pptx`. Keep the
version that was presented, unchanged, even after you improve it, because **the decision was made on that
version**, and a later question about the decision has to be answered from it.
