---
title: Choosing a tool
version: 1
---

Three tools gave the same answer, so the choice between them is not about correctness. It is about
everything around the answer:

| | Spreadsheet | Power Query | SQL | pandas | dplyr |
|---|---|---|---|---|---|
| Records what was done | no | yes, as steps | yes, as a query | yes, as a script | yes, as a script |
| Guesses types unless told | on opening | when importing, editable | no: casts or fails | yes, unless `dtype=str` | yes, unless `col_types` |
| Easy to review in a diff | no | possible, as M code | yes | yes | yes |
| Good at | looking, small fixes | repeatable imports | data where it lives | exploring, fuzzy work | readable pipelines |

A few rules follow from the table, and they are the same whatever the tool:

- **The tool that records the work is the one to clean with.** A change typed into a cell is a
  change nobody can rerun, review or undo next month. Lesson 17 is about exactly this.
- **Use the tool the next reader can read.** A query for a team that works in SQL, a script for a
  team that works in Python or R, Power Query for a team that lives in Excel. A cleaning nobody else
  can follow is a cleaning that will be done again from scratch.
- **Move between tools at clean boundaries**, with types stated on both sides: a CSV written with
  codes as text and read with `dtype=str`, or a table in the database with its types and checks.
  Most of the defects in this course were created exactly at such a crossing, by a tool that guessed.
- **When two tools must agree, prove it**, as this lesson did: the same specification, two
  implementations, the same numbers.

None of the four is the professional one and the others amateur. **The professional habit is the
written task, the recorded steps and the cross-check**, and every tool here supports them.
