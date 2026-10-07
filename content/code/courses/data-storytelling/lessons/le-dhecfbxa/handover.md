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

Every number in this course about Faro's customers can be recomputed from the twenty-four rows of
`faro.csv`, the table you saved in lesson 1, and the lessons that compute one show the formula. The facts the
table does not hold, such as the price of a box, the margin, the renewal deliveries and the pilot's weekly
rates, are stated once, in the lesson that introduces them, and reused from there. **Nothing is retyped**,
which is why a number in lesson 11 and the same number in lesson 4 cannot disagree.

That is the standard to aim at, and it needs no programming: a spreadsheet whose numbers all come from
formulas over one data tab is reproducible. What breaks reproducibility is the number typed by hand
into a slide, which nobody can trace and nobody updates when the data changes.

## Versions

Name versions by date, not by "final": `first-delivery-2025-08-15.pptx`, not `final-v3-REAL.pptx`. Keep the
version that was presented, unchanged, even after you improve it, because **the decision was made on that
version**, and a later question about the decision has to be answered from it.
