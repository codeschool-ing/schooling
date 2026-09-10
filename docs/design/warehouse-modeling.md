---
format: 5
course: warehouse-modeling
---

# warehouse-modeling

**Data Modelling and the Data Warehouse** · `co-52kx69ea` · 70 h declared · intermediate · 12 lessons · `data` · paid

## Reach

In **3 tracks** — `bi`(11), `data`(9), `software-architecture`(10).

**Depends on it:** `pipelines-etl`

## Assumes, and leaves ready

**Assumes:** `sql-databases` — tables, keys, joins and normalisation, which this course spends half its time arguing against.

**Leaves ready:** dimensional modelling, for `pipelines-etl`.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 12 |
| **hours per lesson** | **5.83** |
| section budget | ~150, about 12.5 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a database, and preferably a columnar one** |
| browser · database | no · **yes** — a star schema is not understood by reading one |
| exercises **blocked** | **~250 (35%)** — the modelling half grades on paper, the querying half does not |
| exercises that would **improve** | ~150 |
| diagrams to draw | ~70 — every star and snowflake, each SCD type drawn over time, grain shown as rows, columnar storage against row storage |

## Ageing

**Low.** Kimball is thirty years old. Lesson 9 names BigQuery, Snowflake and Redshift, and lesson 11 names data mesh — those move; the modelling does not.

## Flags

**1 ·** **Twelve lessons for seventy hours — 12.5 sections each, the widest ratio in the category and among the widest in the catalogue.** Lesson 5 is all three slowly-changing-dimension types. These are small courses wearing lesson titles, and the section design has to treat them that way or two thirds of the declared hours have nothing behind them.

**2 ·** **The most gradeable course in `data` that still needs a database.** Choosing a grain, picking a surrogate key, deciding an SCD type, spotting a fact table that is really a dimension — those are `quiz`, `matching` and `ordering` items on paper, no environment needed. **Roughly two thirds of it is publishable now**, which is the best ratio of any course in the category outside `statistics` and `data-fundamentals`.

**3 ·** **It is in three tracks including `software-architecture`**, which continues `backend` — so one of its audiences is an architect who will never build a warehouse and needs the vocabulary to argue about one. Same divergence `architect-communication` has, and the same cheap answer: name both readers in the material.
