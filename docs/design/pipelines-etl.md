---
format: 5
course: pipelines-etl
---

# pipelines-etl

**Data Pipelines and ETL** · `co-2q13eccx` · 70 h declared · intermediate · 19 lessons · `data` · paid

## Reach

In **2 tracks** — `bi`(12), `data`(11).

**Depends on it:** `ml-mlops`

## Assumes, and leaves ready

**Assumes:** `warehouse-modeling` — the destination. A pipeline is defined by what it is loading into, which is why this order is right.

**Leaves ready:** orchestration and data quality, for `ml-mlops`.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 19 |
| **hours per lesson** | **3.68** |
| section budget | ~150, about 7.9 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a scheduler with somewhere to write** — Airflow and dbt, a database, and time that passes |
| browser · database | Airflow's interface is a browser one · **yes** |
| exercises **blocked** | **~450 (60%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — a DAG, ETL against ELT, a watermark advancing, an SCD type 2 load, a backfill over a calendar |

## Ageing

**Moderate.** Airflow and dbt are both moving targets, and lesson 13 names three alternatives that may not all outlive the course.

## Flags

**1 ·** **It needs time to pass, which no sandbox in the catalogue provides.** Lesson 9 is scheduling, sensors, backfill and catch-up; lesson 10 is *"the pipeline that failed at 3am"*. A student cannot experience a scheduled job without a schedule, and compressing a day into a minute is a fixture design problem nobody has framed. **This is a new axis** — every other blocked course needs a machine, and this one needs a clock.

**2 ·** **Idempotency is the course's spine and it is machine-checkable.** Lesson 15 is safe reprocessing; run it twice and compare. That is `expected-output` on a table, the same shape `sql-databases` needs, and building it once serves both.

**3 ·** **Two tracks, and one dependent in a third.** `bi`(12), `data`(11), and `ml-mlops` in `data-platform` requires it. Middling reach, high environment cost, and one of the few courses whose prerequisite chain is entirely inside this category.
