---
format: 5
course: data-cleaning
---

# data-cleaning

**Data Cleaning and Preparation** · `co-yysxgjxd` · 60 h declared · intermediate · 17 lessons · `data` · paid

## Reach

In **2 tracks** — `bi`(6), `data-science`(6).

**Depends on it:** `visualization`

## Assumes, and leaves ready

**Assumes:** `statistics` and `sql-databases` — distributions and outliers from one, joins and cardinality from the other. Both are load-bearing here.

**Leaves ready:** clean data, for `visualization`. The dependency is real: you cannot chart what you have not fixed.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 17 |
| **hours per lesson** | **3.53** |
| section budget | ~129, about 7.6 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **pandas or SQL, and preferably both** — lesson 16 names Excel, SQL, pandas and dplyr |
| browser · database | a notebook · **yes, for the SQL half** |
| exercises **blocked** | **~400 (65%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — a profile of a dirty column, missingness patterns, fuzzy matching, wide against long, a join fanning out |

## Ageing

**None.** Dirty data is dirty in the same ways it always was.

## Flags

**1 ·** **The one course whose exercises need deliberately broken fixtures**, and that is a content problem rather than an environment one. Every other blocked course needs a machine; this one needs *data with the right defects in it* — a column where missing means zero, a duplicate that is not exact, an outlier that is a real event. **Those fixtures are authored material and belong in `content/`**, which means the course is much closer to buildable than its 65% suggests: the runtime helps, but the teaching is in the fixture.

**2 ·** **Lesson 3 is the whole course in one title** — *"Missing values: why they are missing and what that means"* — and it is judgement, not technique. The technique lessons grade with `expected-output`; the judgement ones need the scenario treatment `management` needed. Same split, inside one course.

**3 ·** **Two tracks and one dependent, and it is the load-bearing course of the analyst path.** `bi`(6) and `data-science`(6) both reach it at position 6, and `visualization` requires it. The most-used course in the category after the two hubs.
