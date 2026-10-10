---
title: What a week of the work looks like
version: 1
---

**Job adverts describe the data engineer's week as building pipelines. Most of it is keeping them
alive.** Here is Davi's, the week ana arrives, as a list of what actually happened. Every item is a
kind of work this course names, and the lesson that names it is beside it.

| day | what happened | what kind of work it is | lesson |
|---|---|---|---|
| Monday | the sensors' file for Sunday was missing at 06:00; it arrived at 09:40 and the morning report ran late | **freshness**: data that is right but not on time | 2, 7 |
| Monday | Marta asked for empty stations last week | **a request**: turning a question into data that can answer it | 1 |
| Tuesday | the app team added a field `promo_code` to rides; the nightly copy ignored it | **schema change** in a source | 4, 5 |
| Wednesday | a ride appeared twice in the rides table after a job was retried | **idempotency**: a step that is safe to run twice | 3, 9 |
| Wednesday | ana asked why the sensor history is kept as Parquet and not CSV | **a format decision** | 6 |
| Thursday | the payments provider's API started refusing calls after 100 a minute | **a source's limits**: rate limiting | 4, 7 |
| Thursday | the storage bill went up by a third in a month | **cost** | 2, 7 |
| Friday | Caio asked for the dock readings as they happen, not the next morning | **batch or stream** | 8 |
| Friday | a disk on the server holding the raw files filled up | **operations**: the machine under it all | 9 |

Two requests, one design question, and six things that broke or nearly broke. That ratio is normal,
and it explains the most important habit in the job: **a pipeline is built to be operated,
not only to run.** It says when it fails, it can be run again safely, and somebody other than its
author can tell what it did last night.

## The pyramid it serves

Monica Rogati drew the needs of a data-driven company as a pyramid, and the drawing has lasted
because it explains why so many companies hire a data scientist first and regret it:

1. **collect** — the data is recorded at all;
2. **move and store** — it reaches somewhere it can be read, reliably;
3. **explore and transform** — it is cleaned and shaped into something meaningful;
4. **aggregate and label** — metrics, segments, the training data a model needs;
5. **learn and optimise** — experiments, predictions, AI.

Each level rests on the ones beneath it. **The data engineer's work is the bottom three**, and the
top two cannot be built on a foundation that is missing. A data scientist hired into a company
without the first three spends most of the first year doing a data engineer's work, usually without
the tools and the habits for it.

## What the job is not

It is not database administration, though it borrows from it. A database administrator keeps one
database fast and safe; a data engineer moves data between many systems and owns what happens in
between. And it is not "the person who writes the SQL for the analysts". Writing SQL is a skill the
job uses every day, and `sql-databases` teaches it; the job is the system around the SQL.
